local M = {}

local platform = require("soul.core.platform")
local process_helper = require("soul.core.helpers.process")
local fn = vim.fn

local projects_dir = vim.env.PROJECTS_DIR
M.projects = projects_dir and vim.trim(projects_dir) ~= "" and vim.trim(projects_dir)
	or (platform.is_windows and "D:/config/projects")
	or fn.expand("~/projects")

local function find_executable(names)
	for _, name in ipairs(names) do
		local executable = fn.exepath(name)
		if executable ~= "" then
			return executable
		end
	end
end

local probe_budget_ms = 6000
local probe_timeout_ms = 1500

local function remaining_probe_time(deadline)
	return math.max(0, math.floor((deadline - vim.uv.hrtime()) / 1e6))
end

local function run_probe(command, deadline)
	local remaining = remaining_probe_time(deadline)
	if remaining <= 0 then
		return
	end

	local ok, child = pcall(vim.system, command, { text = true })
	if not ok then
		return
	end

	local result = process_helper.wait(child, math.min(remaining, probe_timeout_ms))
	if not result then
		return nil
	end

	return result
end

local function is_runnable_powershell(path, deadline)
	if type(path) ~= "string" or path == "" or fn.executable(path) ~= 1 then
		return false
	end

	-- Store App Execution Aliases can launch through vim.system(), but
	-- termopen() needs a real executable path.
	local result = run_probe({
		path,
		"-NoLogo",
		"-NoProfile",
		"-NonInteractive",
		"-Command",
		"[Console]::Out.Write([int]$PSVersionTable.PSVersion.Major)",
	}, deadline)

	if type(result) ~= "table" or result.code ~= 0 then
		return false
	end

	local major = tonumber((result.stdout or ""):match("%d+"))
	return major ~= nil and major >= 7
end

local function powershell_home(path, deadline)
	if type(path) ~= "string" or path == "" then
		return
	end

	local result = run_probe({
		path,
		"-NoLogo",
		"-NoProfile",
		"-NonInteractive",
		"-Command",
		"[Console]::Out.Write($PSHOME)",
	}, deadline)

	if type(result) == "table" and result.code == 0 then
		local home = vim.trim(result.stdout or "")
		if home ~= "" then
			return home
		end
	end
end

local function find_powershell()
	local deadline = vim.uv.hrtime() + probe_budget_ms * 1e6
	local candidates = {}
	local seen = {}

	local function add_candidate(path)
		if type(path) ~= "string" or path == "" then
			return
		end

		-- Resolve command names such as PWSH=pwsh to their actual executable.
		-- The C runner and termopen need a concrete path, not a PATH token.
		if not path:find("[/\\\\]") then
			local resolved = fn.exepath(path)
			if resolved ~= "" then
				path = resolved
			end
		end

		local key = platform.is_windows and path:lower() or path
		if not seen[key] then
			seen[key] = true
			candidates[#candidates + 1] = path
		end
	end

	-- PSHOME is already known when Neovim was launched from PowerShell.
	-- Prefer its concrete executable before probing command aliases or invoking
	-- Windows PowerShell to query the Store package location.
	if platform.is_windows and vim.env.PSHOME then
		add_candidate(vim.env.PSHOME .. "/pwsh.exe")
	end

	add_candidate(vim.env.PWSH)

	local pwsh = fn.exepath("pwsh")
	local pwsh_exe = fn.exepath("pwsh.exe")
	add_candidate(pwsh)
	add_candidate(pwsh_exe)

	local function resolve_candidates()
		for _, candidate in ipairs(candidates) do
			if remaining_probe_time(deadline) <= 0 then
				break
			end

			if is_runnable_powershell(candidate, deadline) then
				local normalized = candidate:gsub("\\", "/"):lower()
				local is_store_alias = platform.is_windows and normalized:find("/windowsapps/", 1, true) ~= nil

				if is_store_alias then
					-- Store aliases can be spawned but are not reliable termopen
					-- shells. Resolve the real package executable only on demand.
					local home = powershell_home(candidate, deadline)
					if home then
						local executable = home .. "/pwsh.exe"
						if is_runnable_powershell(executable, deadline) then
							return executable
						end
					end
				else
					return candidate
				end
			end
		end
	end

	local resolved = resolve_candidates()
	if resolved then
		return resolved
	end

	if platform.is_windows then
		local function add_program_files(root)
			if type(root) == "string" and root ~= "" then
				add_candidate(root .. "/PowerShell/7/pwsh.exe")
			end
		end

		-- Check every standard install root. ProgramFiles can point at the
		-- 32-bit directory in some process environments.
		add_program_files(vim.env.ProgramW6432)
		add_program_files(vim.env.ProgramFiles)
		add_program_files(vim.env["ProgramFiles(x86)"])
		add_program_files("C:/Program Files")
		add_program_files("C:/Program Files (x86)")

		local local_programs = vim.env.LOCALAPPDATA
		if local_programs then
			add_candidate(local_programs .. "/Programs/PowerShell/7/pwsh.exe")
		end

		-- Slow discovery is a fallback, not a startup prerequisite. Only reach
		-- these probes when known executable paths did not resolve.
		local where_result = run_probe({ "where.exe", "pwsh.exe" }, deadline)
		if type(where_result) == "table" and where_result.code == 0 then
			local matches = vim.split(vim.trim(where_result.stdout or ""), "\n", {
				trimempty = true,
			})
			for i = #matches, 1, -1 do
				add_candidate(vim.trim(matches[i]))
			end
		end

		local resolved_programs = resolve_candidates()
		if resolved_programs then
			return resolved_programs
		end

		-- The alias may not be discoverable through PATH when Neovim is launched
		-- outside PowerShell. Windows PowerShell is used only to ask AppX for
		-- the Store package location; it is never selected as the shell.
		local windows_powershell = fn.exepath("powershell.exe")
		if windows_powershell ~= "" then
			local result = run_probe({
				windows_powershell,
				"-NoLogo",
				"-NoProfile",
				"-NonInteractive",
				"-Command",
				"(Get-AppxPackage -Name Microsoft.PowerShell | Select-Object -First 1 -ExpandProperty InstallLocation)",
			}, deadline)

			if type(result) == "table" and result.code == 0 then
				local install_location = vim.trim(result.stdout or "")
				if install_location ~= "" then
					add_candidate(install_location .. "/pwsh.exe")
				end
			end
		end
	else
		add_candidate(fn.exepath("powershell"))
	end

	resolved = resolve_candidates()
	if resolved then
		return resolved
	end

	-- Never silently fall back to Windows PowerShell 5.1.
	-- Let the shell report a clear error if PowerShell 7 is unavailable.
	return "pwsh"
end

M.clang = vim.env.CLANG and fn.executable(vim.env.CLANG) == 1 and vim.env.CLANG
	or find_executable({ "clang" })
	or "clang"

M.pwsh = find_powershell()

local lldb_dap = vim.env.LLDB_DAP
M.lldb_dap = lldb_dap and vim.trim(lldb_dap) ~= "" and vim.trim(lldb_dap)
	or (platform.is_windows and "C:/Program Files/LLVM/bin/lldb-dap.exe")
	or "lldb-dap"

-- Windows clipboard tools are only resolved when Neovim itself runs in WSL.
if platform.is_wsl then
	local copy = find_executable({ "clip.exe" })
	local paste = find_executable({ "powershell.exe", "pwsh.exe" })

	if copy and paste then
		M.wsl_clipboard = {
			copy = copy,
			paste = paste,
		}
	end
end

return M
