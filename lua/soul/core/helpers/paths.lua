local M = {}

local platform = require("soul.core.platform")

M.projects = vim.env.PROJECTS_DIR
	or (platform.is_windows and "D:/config/projects")
	or vim.fn.expand("~/projects")

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

M.pwsh = find_powershell()

M.lldb_dap = vim.env.LLDB_DAP
	or (platform.is_windows and "C:/Program Files/LLVM/bin/lldb-dap.exe")
	or "lldb-dap"

return M
