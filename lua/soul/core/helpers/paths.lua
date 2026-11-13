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

local function resolve_clang()
	local configured = vim.env.CLANG
	if configured and fn.executable(configured) == 1 then
		return configured
	end

	return find_executable({ "clang" }) or "clang"
end

local function resolve_pwsh()
	local configured = vim.env.PWSH and vim.trim(vim.env.PWSH)
	local configured_name = configured and configured ~= "" and configured:gsub("\\", "/"):match("([^/]+)$")
	configured_name = configured_name and configured_name:lower()
	local configured_is_pwsh = configured_name == "pwsh" or configured_name == "pwsh.exe"

	if configured_is_pwsh and fn.executable(configured) == 1 then
		return configured
	end

	return find_executable({ "pwsh" }) or "pwsh"
end

-- Compiler and shell discovery are deferred until a feature actually needs them.
setmetatable(M, {
	__index = function(tbl, key)
		local value
		if key == "clang" then
			value = resolve_clang()
		elseif key == "pwsh" then
			value = resolve_pwsh()
		else
			return nil
		end

		rawset(tbl, key, value)
		return value
	end,
})

-- The WSL interop PATH resolves these command names when clipboard is used.
-- Avoid scanning the full PATH during every empty startup.
if platform.is_wsl then
	M.wsl_clipboard = {
		copy = "clip.exe",
		paste = "powershell.exe",
	}
end

-- The resolver module itself is loaded only when a feature requests PowerShell.
function M.resolve_powershell()
	return require("soul.core.helpers.powershell").resolve()
end

local lldb_dap = vim.env.LLDB_DAP
M.lldb_dap = lldb_dap and vim.trim(lldb_dap) ~= "" and vim.trim(lldb_dap)
	or (platform.is_windows and "C:/Program Files/LLVM/bin/lldb-dap.exe")
	or "lldb-dap"

return M
