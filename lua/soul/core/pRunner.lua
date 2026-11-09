-- lua/soul/core/pRunner.lua
local paths = require("soul.core.paths")

local function open_build_float()
  local buf = vim.api.nvim_create_buf(false, true)

  local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.8)))
  local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.7)))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Preparing build..." })

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
  vim.bo[buf].filetype = "log"

  local function append(lines)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    vim.bo[buf].modifiable = true
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)
    vim.bo[buf].modifiable = false

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_cursor(win, {
        vim.api.nvim_buf_line_count(buf),
        0,
      })
    end
  end

  vim.keymap.set("n", "q", "<cmd>close<CR>", {
    buffer = buf,
    silent = true,
    desc = "Close build output",
  })

  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", {
    buffer = buf,
    silent = true,
    desc = "Close build output",
  })

  return {
    buf = buf,
    win = win,
    append = append,
  }
end

local function append_job_output(view, data, pending)
  if not data or #data == 0 then
    return pending
  end

  local lines = vim.deepcopy(data)
  lines[1] = (pending or "") .. lines[1]

  pending = table.remove(lines) or ""

  if #lines > 0 then
    view.append(lines)
  end

  return pending
end

local function run_build(directory, view, on_exit)
  local command

  if paths.is_windows then
    command = {
      paths.pwsh,
      "-NoLogo",
      "-NoProfile",
      "-NonInteractive",
      "-Command",
      "& '.\\build.bat'; exit $LASTEXITCODE",
    }
  else
    command = { "bash", "./build.sh" }
  end

  local pending = {
    stdout = "",
    stderr = "",
  }

  local function flush_output()
    local lines = {}

    for _, stream in ipairs({ "stdout", "stderr" }) do
      if pending[stream] ~= "" then
        table.insert(lines, pending[stream])
        pending[stream] = ""
      end
    end

    if #lines > 0 then
      view.append(lines)
    end
  end

  local job_id = vim.fn.jobstart(command, {
    cwd = directory,
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data)
      vim.schedule(function()
        pending.stdout = append_job_output(view, data, pending.stdout)
      end)
    end,

    on_stderr = function(_, data)
      vim.schedule(function()
        pending.stderr = append_job_output(view, data, pending.stderr)
      end)
    end,

    on_exit = function(_, exit_code)
      vim.schedule(function()
        flush_output()
        on_exit(exit_code)
      end)
    end,
  })

  if job_id <= 0 then
    vim.schedule(function()
      on_exit(job_id)
    end)
  end

  return job_id
end

local function build_s3d()
  local view = open_build_float()
  local s3d = paths.s3d

  if vim.fn.isdirectory(s3d) ~= 1 then
    view.append({
      "",
      "S3D directory not found:",
      s3d,
    })
    return
  end

  local function finish(message)
    view.append({ "", message })
  end

  view.append({
    "",
    "Building S3D engine...",
  })

  run_build(s3d .. "/engine", view, function(engine_exit)
    if engine_exit ~= 0 then
      finish("Engine build failed. Exit code: " .. engine_exit)
      return
    end

    finish("Engine build succeeded.")
    view.append({ "", "Building S3D testbed..." })

    run_build(s3d .. "/testbed", view, function(testbed_exit)
      if testbed_exit ~= 0 then
        finish("Testbed build failed. Exit code: " .. testbed_exit)
        return
      end

      finish("Testbed build succeeded.")

      local executable = paths.is_windows
          and (s3d .. "/bin/testbed.exe")
        or (s3d .. "/bin/testbed")

      if vim.fn.filereadable(executable) ~= 1 then
        view.append({
          "",
          "Could not find testbed executable:",
          executable,
        })
        return
      end

      local job_id = vim.fn.jobstart({ executable }, {
        cwd = s3d,
        detach = true,
      })

      if job_id <= 0 then
        finish("Failed to launch testbed. Job error: " .. job_id)
      else
        finish("S3D rebuilt and testbed launched.")
      end
    end)
  end)
end

vim.keymap.set("n", "<leader>nn", build_s3d, {
  desc = "Build and run S3D",
})
