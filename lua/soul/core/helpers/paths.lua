local M = {}

local platform = require("soul.core.platform")
local fn = vim.fn

local projects_dir = vim.env.PROJECTS_DIR
M.projects = projects_dir and vim.trim(projects_dir) ~= "" and vim.trim(projects_dir) or fn.expand("~/projects")

local function find_executable(names)
	for _, name in ipairs(names) do
		local executable = fn.exepath(name)
		if executable ~= "" then
			return executable
		end
	end
end


M.clang = vim.env.CLANG and fn.executable(vim.env.CLANG) == 1 and vim.env.CLANG
	or find_executable({ "clang" })
	or "clang"

-- Cheap PATH lookup for Neovim's shell option. Full PowerShell validation stays lazy.
local configured_powershell = vim.env.PWSH and vim.trim(vim.env.PWSH)
local configured_name = configured_powershell
	and configured_powershell ~= ""
	and configured_powershell:gsub("\\", "/"):match("([^/]+)$")
configured_name = configured_name and configured_name:lower()
local configured_is_pwsh = configured_name == "pwsh" or configured_name == "pwsh.exe"
M.pwsh = configured_is_pwsh and fn.executable(configured_powershell) == 1 and configured_powershell
	or fn.exepath("pwsh")
	or "pwsh"

-- The resolver module itself is loaded only when a feature requests PowerShell.
function M.resolve_powershell()
	return require("soul.core.helpers.powershell").resolve()
end

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
