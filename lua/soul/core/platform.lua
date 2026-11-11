local M = {}

local has = vim.fn.has
local is_unix = has("unix") == 1
local release = (vim.uv.os_uname().release or ""):lower()

M.is_windows = has("win32") == 1
M.is_wsl = not M.is_windows
	and is_unix
	and (
		vim.env.WSL_DISTRO_NAME ~= nil
		or vim.env.WSL_INTEROP ~= nil
		or release:find("microsoft", 1, true) ~= nil
		or release:find("wsl", 1, true) ~= nil
	)
M.is_termux = is_unix
	and not M.is_wsl
	and (
		vim.env.TERMUX_VERSION ~= nil
		or (vim.env.PREFIX or ""):find("/com.termux/", 1, true) ~= nil
	)
M.is_linux = is_unix and not M.is_wsl and not M.is_termux
M.is_unix = is_unix

if M.is_windows then
	M.name = "windows"
elseif M.is_wsl then
	M.name = "wsl"
elseif M.is_termux then
	M.name = "termux"
elseif M.is_linux then
	M.name = "linux"
else
	M.name = "unknown"
end

function M.is(name)
	return M.name == name
end

return M
