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
local function find_powershell()
  if vim.env.PWSH and vim.fn.executable(vim.env.PWSH) == 1 then
    return vim.env.PWSH
  end

  local pwsh = vim.fn.exepath("pwsh")
  if pwsh ~= "" then
    return pwsh
  end

  if M.is_windows then
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

-- LLDB DAP adapter
M.lldb_dap = vim.env.LLDB_DAP
  or (M.is_windows and "C:/Program Files/LLVM/bin/lldb-dap.exe")
  or "lldb-dap"

return M
