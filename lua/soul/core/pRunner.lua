-- lua/soul/core/pRunner.lua
local paths = require("soul.core.paths")

local function open_build_float(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width  = math.max(1, math.floor(vim.o.columns * 0.8))
  local height = math.max(1, math.floor(vim.o.lines * 0.7))
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width, height = height,
    row = row, col = col,
    style = "minimal", border = "rounded",
  })

  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].filetype   = "log"

  vim.keymap.set("n", "q",     "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
end

local function run_build(directory, output)
  local is_win = paths.is_windows
  local cmd

  if is_win then
    cmd = {
      paths.pwsh, "-NoLogo", "-NoProfile", "-NonInteractive", "-Command",
      string.format(
        "$ErrorActionPreference = 'Stop'; Set-Location -LiteralPath '%s'; & '.\\build.bat'; exit $LASTEXITCODE",
        directory
      ),
    }
  else
    cmd = { "bash", "-lc", string.format("cd %q && ./build.sh", directory) }
  end

  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if type(result) ~= "string" then
    result = "Failed to execute build command"
  end

  vim.list_extend(output, vim.split(result, "\n", { plain = true, trimempty = true }))
  return exit_code
end

vim.keymap.set("n", "<leader>nn", function()
  local output = {}
  local s3d = paths.s3d

  if vim.fn.isdirectory(s3d) ~= 1 then
    table.insert(output, "S3D directory not found: " .. s3d)
    open_build_float(output)
    return
  end

  table.insert(output, "Building S3D engine...")
  local engine_exit = run_build(s3d .. "/engine", output)

  if engine_exit ~= 0 then
    table.insert(output, "")
    table.insert(output, "Engine build failed")
    table.insert(output, "Exit code: " .. engine_exit)
    open_build_float(output)
    return
  end

  table.insert(output, "")
  table.insert(output, "Engine build succeeded")
  table.insert(output, "")
  table.insert(output, "Building S3D testbed...")

  local testbed_exit = run_build(s3d .. "/testbed", output)

  if testbed_exit ~= 0 then
    table.insert(output, "")
    table.insert(output, "Testbed build failed")
    table.insert(output, "Exit code: " .. testbed_exit)
    open_build_float(output)
    return
  end

  table.insert(output, "")
  table.insert(output, "Testbed build succeeded")

  local exe = paths.is_windows
    and (s3d .. "/bin/testbed.exe")
    or  (s3d .. "/bin/testbed")

  if vim.fn.filereadable(exe) ~= 1 then
    table.insert(output, "")
    table.insert(output, "Could not find testbed executable:")
    table.insert(output, exe)
    open_build_float(output)
    return
  end

  local job_id = vim.fn.jobstart({ exe }, {
    cwd = s3d,
    detach = true,
  })

  table.insert(output, "")
  if job_id <= 0 then
    table.insert(output, "Failed to launch testbed")
  else
    table.insert(output, "S3D rebuilt + launched")
  end

  open_build_float(output)
end, { desc = "Build and run S3D" })
