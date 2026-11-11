local M = {}

local platform = require("soul.core.platform")

M.projects = vim.env.PROJECTS_DIR
	or (platform.is_windows and "D:/config/projects")
	or vim.fn.expand("~/projects")

local function find_executable(names)
	for _, name in ipairs(names) do
		local executable = vim.fn.exepath(name)
		if executable ~= "" then
			return executable
		end
	end
end

local function find_powershell()
	if vim.env.PWSH and vim.fn.executable(vim.env.PWSH) == 1 then
		return vim.env.PWSH
	end

	local pwsh = vim.fn.exepath("pwsh")
	if pwsh ~= "" then
		return pwsh
	end

	if platform.is_windows then
		local program_files = vim.env.ProgramFiles or "C:/Program Files"
		local pwsh_path = program_files .. "/PowerShell/7/pwsh.exe"

		if vim.fn.executable(pwsh_path) == 1 then
			return pwsh_path
		end

		local powershell = vim.fn.exepath("powershell.exe")
		if powershell ~= "" then
			return powershell
		end

		return "powershell.exe"
	end

	return "pwsh"
end

M.clang = vim.env.CLANG and vim.fn.executable(vim.env.CLANG) == 1 and vim.env.CLANG
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
