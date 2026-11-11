local M = {}

local has = vim.fn.has
local uname = vim.uv.os_uname()
local system = (uname.sysname or ""):lower()
local release = (uname.release or ""):lower()

local function present(value)
	return type(value) == "string" and value ~= ""
end

local function read_kernel_info(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok or type(lines) ~= "table" then
		return ""
	end
	return table.concat(lines, " "):lower()
end

local is_linux_kernel = system == "linux"
local kernel_info = release .. " " .. read_kernel_info("/proc/version")

M.is_windows = has("win32") == 1 or system == "windows_nt"
M.is_wsl = is_linux_kernel
	and (
		present(vim.env.WSL_DISTRO_NAME)
		or present(vim.env.WSL_INTEROP)
		or present(vim.env.WSLENV)
		or kernel_info:find("microsoft", 1, true) ~= nil
		or kernel_info:find("wsl", 1, true) ~= nil
	)
M.is_termux = is_linux_kernel
	and not M.is_wsl
	and (
		present(vim.env.TERMUX_VERSION)
		or (vim.env.PREFIX or ""):find("/com.termux/", 1, true) ~= nil
	)
M.is_linux = is_linux_kernel and not M.is_wsl and not M.is_termux
M.is_macos = system == "darwin"
M.is_unix = is_linux_kernel or M.is_macos or has("unix") == 1
M.is_posix = M.is_linux or M.is_wsl or M.is_macos or M.is_termux

if M.is_windows then
	M.name = "windows"
elseif M.is_wsl then
	M.name = "wsl"
elseif M.is_linux then
	M.name = "linux"
elseif M.is_termux then
	M.name = "termux"
elseif M.is_macos then
	M.name = "macos"
else
	M.name = "unknown"
end

M.executable_suffix = M.is_windows and ".exe" or ""
M.path_separator = M.is_windows and "\\" or "/"

function M.is(name)
	return M.name == name
end

return M
