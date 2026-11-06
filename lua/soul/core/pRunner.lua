local s3d_dir = "D:/config/projects/"
local code_dir = s3d_dir .. "/s3d"

local pwsh = "C:/Program Files/WindowsApps/Microsoft.PowerShell_7.6.7.0_x64__8wekyb3d8bbwe/pwsh.exe"

local function open_build_float(lines)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.max(1, math.floor(vim.o.columns * 0.8))
  local height = math.max(1, math.floor(vim.o.lines * 0.7))

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "log"

  vim.keymap.set("n", "q", "<cmd>close<CR>", {
    buffer = buf,
    silent = true,
  })

  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", {
    buffer = buf,
    silent = true,
  })

  return buf
end

local function run_build(directory, output)
  local command = {
    pwsh,
    "-NoLogo",
    "-NoProfile",
    "-NonInteractive",
    "-Command",
    "$ErrorActionPreference = 'Stop'; " ..
      "Set-Location -LiteralPath '" .. directory .. "'; " ..
      "& '.\\build.bat'; " ..
      "exit $LASTEXITCODE",
  }

  local result = vim.fn.system(command)
  local exit_code = vim.v.shell_error

  if type(result) ~= "string" then
    result = "Failed to execute PowerShell.\nExecutable: " .. pwsh
  end

  vim.list_extend(output, vim.split(result, "\n", {
    plain = true,
    trimempty = true,
  }))

  return exit_code
end

vim.keymap.set("n", "<leader>nn", function()
  local output = {}

  if vim.fn.executable(pwsh) ~= 1 then
    table.insert(output, "PowerShell executable not found:")
    table.insert(output, pwsh)
    open_build_float(output)
    return
  end

  table.insert(output, "Building S3D engine...")
  table.insert(output, "")

  local engine_exit = run_build(code_dir .. "/engine", output)

  if engine_exit ~= 0 then
    table.insert(output, "")
    table.insert(output, "Engine build failed ❌")
    table.insert(output, "Exit code: " .. engine_exit)

    open_build_float(output)
    return
  end

  table.insert(output, "")
  table.insert(output, "Engine build succeeded ✅")
  table.insert(output, "")
  table.insert(output, "Building S3D testbed...")

  local testbed_exit = run_build(code_dir .. "/testbed", output)

  if testbed_exit ~= 0 then
    table.insert(output, "")
    table.insert(output, "Testbed build failed ❌")
    table.insert(output, "Exit code: " .. testbed_exit)

    open_build_float(output)
    return
  end

  table.insert(output, "")
  table.insert(output, "Testbed build succeeded ✅")

  local executable = code_dir .. "/bin/testbed.exe"

  if vim.fn.filereadable(executable) ~= 1 then
    table.insert(output, "")
    table.insert(output, "Could not find testbed executable:")
    table.insert(output, executable)

    open_build_float(output)
    return
  end

  local job_id = vim.fn.jobstart({ executable }, {
    cwd = code_dir,
    detach = true,
  })

  table.insert(output, "")

  if job_id <= 0 then
    table.insert(output, "Failed to launch testbed ❌")
    table.insert(output, "Job ID: " .. job_id)
  else
    table.insert(output, "S3D rebuilt + launched ✅")
  end

  open_build_float(output)
end, {
  desc = "Build and run S3D",
})

