local M = {}

local platform = require("soul.core.platform")
local fn = vim.fn

M.projects = vim.env.PROJECTS_DIR
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

local function is_runnable_powershell(path)
	if type(path) ~= "string" or path == "" or fn.executable(path) ~= 1 then
		return false
	end

	-- An App Execution Alias can exist and still fail to launch. Verify the
	-- candidate itself rather than trusting PATH or where.exe output.
	local ok, result = pcall(function()
		local process = vim.system({
			path,
			"-NoLogo",
			"-NoProfile",
			"-Command",
			"Write-Output $PSVersionTable.PSVersion.Major",
		}, { text = true })

		local completed = process:wait(2000)
		if not completed then
			pcall(process.kill, process, 9)
		end

		return completed
	end)

	local major = ok and type(result) == "table"
		and result.code == 0
		and tonumber(vim.trim(result.stdout or ""))

	return type(major) == "number" and major >= 7
end

local function find_powershell()
	local candidates = {}
	local seen = {}

	local function add_candidate(path)
		if type(path) ~= "string" or path == "" then
			return
		end

		local key = platform.is_windows and path:lower() or path
		if not seen[key] then
			seen[key] = true
			candidates[#candidates + 1] = path
		end
	end

	add_candidate(vim.env.PWSH)
	add_candidate(fn.exepath("pwsh"))

	if platform.is_windows then
		-- where.exe may list package-specific aliases that cannot be spawned.
		-- Keep the preferred reverse ordering, but validate every candidate.
		local matches = fn.systemlist({ "where.exe", "pwsh.exe" })
		if vim.v.shell_error == 0 then
			for i = #matches, 1, -1 do
				add_candidate(vim.trim(matches[i]))
			end
		end

		local function add_program_files(root)
			if type(root) == "string" and root ~= "" then
				add_candidate(root .. "/PowerShell/7/pwsh.exe")
			end
		end

		-- Check every standard install root. ProgramFiles can point at the
		-- 32-bit directory in some process environments, so do not choose
		-- just one and accidentally skip the 64-bit PowerShell installation.
		add_program_files(vim.env.ProgramW6432)
		add_program_files(vim.env.ProgramFiles)
		add_program_files(vim.env["ProgramFiles(x86)"])
		add_program_files("C:/Program Files")
		add_program_files("C:/Program Files (x86)")

		local local_programs = vim.env.LOCALAPPDATA
		if local_programs then
			add_candidate(local_programs .. "/Programs/PowerShell/7/pwsh.exe")
		end
	else
		add_candidate(fn.exepath("powershell"))
	end

	for _, candidate in ipairs(candidates) do
		if is_runnable_powershell(candidate) then
			return candidate
		end
	end

	-- Never silently fall back to Windows PowerShell 5.1.
	-- Let the shell report a clear error if PowerShell 7 is unavailable.
	return "pwsh"
end

M.clang = vim.env.CLANG and fn.executable(vim.env.CLANG) == 1 and vim.env.CLANG
	or find_executable({ "clang" })
	or "clang"

M.pwsh = find_powershell()

M.lldb_dap = vim.env.LLDB_DAP
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
