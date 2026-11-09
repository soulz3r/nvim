-- lua/soul/core/paths.lua
local M = {}

M.is_windows = vim.fn.has("win32") == 1
M.is_wsl     = vim.fn.has("wsl") == 1
M.is_termux  = vim.fn.has("unix") == 1 and vim.env.TERMUX_VERSION ~= nil
M.is_linux   = vim.fn.has("unix") == 1 and not M.is_termux

-- Prefer an environment variable, then sensible defaults
M.projects = vim.env.PROJECTS_DIR
  or (M.is_windows and "D:/config/projects")
  or vim.fn.expand("~/projects")

M.s3d = M.projects .. "/s3d"

-- PowerShell (Windows only)
M.pwsh = vim.env.PWSH
  or (M.is_windows and (vim.fn.executable("pwsh") == 1 and "pwsh" or "pwsh.exe"))
  or "pwsh"

-- LLDB DAP adapter
M.lldb_dap = vim.env.LLDB_DAP
  or (M.is_windows and "C:/Program Files/LLVM/bin/lldb-dap.exe")
  or "lldb-dap"

return M
