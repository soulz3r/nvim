local s3d_dir = "C:/Users/soulz3r/Desktop/Projects/s3d"
local code_dir = s3d_dir .. "/code"

local function open_build_float(lines)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.7)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
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

  vim.keymap.set("n", "q", "<cmd>close<CR>", {
    buffer = buf,
    silent = true,
  })

  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", {
    buffer = buf,
    silent = true,
  })

  return buf, win
end

vim.keymap.set("n", "<leader>nn", function()
  local pwsh = "pwsh.exe"
  local output = {}

  -- Build engine
  local engine_build = vim.fn.system({
    pwsh,
    "-NoLogo",
    "-NoProfile",
    "-Command",
    'Set-Location "' .. code_dir .. '/engine"; & ".\\build.bat"',
  })

  local engine_exit = vim.v.shell_error

  vim.list_extend(output, vim.split(engine_build, "\n", {
    plain = true,
  }))

  if engine_exit ~= 0 then
    table.insert(output, "")
    table.insert(output, "Engine build failed ❌")

    open_build_float(output)
    return
  end

  -- Build testbed
  local testbed_build = vim.fn.system({
    pwsh,
    "-NoLogo",
    "-NoProfile",
    "-Command",
    'Set-Location "' .. code_dir .. '/testbed"; & ".\\build.bat"',
  })

  local testbed_exit = vim.v.shell_error

  table.insert(output, "")
  vim.list_extend(output, vim.split(testbed_build, "\n", {
    plain = true,
  }))

  if testbed_exit ~= 0 then
    table.insert(output, "")
    table.insert(output, "Testbed build failed ❌")

    open_build_float(output)
    return
  end

  -- Launch testbed
  vim.fn.jobstart({
    "bin/testbed.exe",
  }, {
    cwd = code_dir,
    detach = true,
  })

  table.insert(output, "")
  table.insert(output, "S3D rebuilt + launched ✅")

  open_build_float(output)
end)
