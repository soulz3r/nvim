-- lua/soul/core/pRunner.lua
local paths = require("soul.core.paths")
local connectors = require("soul.core.pRunner.connectors")

local function open_output()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.8)))
  local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.7)))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "log"

  local function append(lines)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    vim.bo[buf].modifiable = false

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
    end
  end

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", {
      buffer = buf,
      silent = true,
      desc = "Close runner output",
    })
  end

  return append
end

local function run_command(command, root, append, callback)
  append({ "", "$ " .. table.concat(command, " ") })

  local pending = ""
  local job = vim.fn.jobstart(command, {
    cwd = root,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if not data then return end
      vim.schedule(function()
        local lines = vim.split(pending .. table.concat(data, "\n"), "\n", { plain = true })
        pending = table.remove(lines) or ""
        if #lines > 0 then append(lines) end
      end)
    end,
    on_stderr = function(_, data)
      if not data then return end
      vim.schedule(function()
        local lines = vim.split(pending .. table.concat(data, "\n"), "\n", { plain = true })
        pending = table.remove(lines) or ""
        if #lines > 0 then append(lines) end
      end)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if pending ~= "" then append({ pending }) end
        callback(code)
      end)
    end,
  })

  if job <= 0 then
    append({ "Could not start process. jobstart returned " .. job })
    callback(job)
  end
end

local function find_executables(root)
  local found = {}
  local is_windows = paths.is_windows
  local names = is_windows and { "%.exe$" } or { "^[^%.]+$" }
  local search_dirs = { "bin", "build", "build/Debug", "build/Release", "Debug", "Release" }

  for _, directory in ipairs(search_dirs) do
    local full = root .. "/" .. directory
    if vim.fn.isdirectory(full) == 1 then
      local files = vim.fs.find(function(name)
        for _, pattern in ipairs(names) do
          if name:match(pattern) then return true end
        end
        return false
      end, { path = full, type = "file", limit = 100 })

      for _, file in ipairs(files) do
        if vim.fn.executable(file) == 1 then
          found[#found + 1] = file
        end
      end
    end
  end

  return found
end

local function launch_project_executable(root, append)
  local executables = find_executables(root)
  if #executables == 0 then
    append({ "", "Build succeeded, but no executable was found in bin/ or build/." })
    return
  end

  local function launch(executable)
    append({ "", "Launching: " .. executable })
    local job = vim.fn.jobstart({ executable }, { cwd = root, detach = true })
    if job <= 0 then append({ "Failed to launch executable. Job error: " .. job }) end
  end

  if #executables == 1 then
    launch(executables[1])
    return
  end

  vim.ui.select(executables, {
    prompt = "Select project executable:",
    format_item = function(item) return vim.fn.fnamemodify(item, ":.") end,
  }, function(choice)
    if choice then launch(choice) end
  end)
end

local function run_project()
  local root = vim.fn.getcwd()
  local connector = connectors.detect(root)
  local append = open_output()

  if not connector then
    append({
      "No supported project connector found.",
      "Supported: build.bat/build.sh, CMake, Make, Cargo, Go, and npm start/dev.",
      "Select the project with <leader>fp first if the working directory is wrong.",
    })
    return
  end

  append({ "Project: " .. root, "Connector: " .. connector.name })

  local function run_or_launch()
    if connector.run then
      run_command(connector.run, root, append, function(code)
        append({ "", code == 0 and "Project finished successfully." or ("Project exited with code " .. code) })
      end)
    else
      launch_project_executable(root, append)
    end
  end

  local function build()
    run_command(connector.build, root, append, function(code)
      if code ~= 0 then
        append({ "", "Build failed. Exit code: " .. code })
        return
      end
      append({ "", "Build succeeded." })
      if connector.run_after_build then run_or_launch() end
    end)
  end

  if connector.configure then
    run_command(connector.configure, root, append, function(code)
      if code ~= 0 then
        append({ "", "CMake configuration failed. Exit code: " .. code })
        return
      end
      build()
    end)
  else
    build()
  end
end

local function run_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Current buffer has no file", vim.log.levels.WARN)
    return
  end

  local root = vim.fn.fnamemodify(file, ":h")
  local extension = vim.fn.fnamemodify(file, ":e"):lower()
  local command
  local output = vim.fn.stdpath("cache") .. "/prunner-file"
  local source = file

  if extension == "c" then
    local compiler = vim.fn.exepath("clang")
    if compiler == "" then compiler = vim.fn.exepath("gcc") end
    if compiler == "" then
      vim.notify("No C compiler found (clang or gcc)", vim.log.levels.ERROR)
      return
    end
    command = { compiler, "-std=c23", "-g", source, "-o", output .. (paths.is_windows and ".exe" or "") }
    local executable = output .. (paths.is_windows and ".exe" or "")
    local append = open_output()
    run_command(command, root, append, function(code)
      if code == 0 then
        run_command({ executable }, root, append, function(run_code)
          append({ "", run_code == 0 and "File finished successfully." or ("File exited with code " .. run_code) })
        end)
      else
        append({ "", "Compilation failed. Exit code: " .. code })
      end
    end)
    return
  elseif extension == "lua" then
    command = { vim.fn.exepath("lua"), source }
  elseif extension == "py" then
    command = { vim.fn.exepath("python"), source }
    if command[1] == "" then command[1] = vim.fn.exepath("python3") end
  elseif extension == "js" then
    command = { vim.fn.exepath("node"), source }
  end

  if not command or command[1] == "" then
    vim.notify("No file runner configured for ." .. extension, vim.log.levels.WARN)
    return
  end

  local append = open_output()
  run_command(command, root, append, function(code)
    append({ "", code == 0 and "File finished successfully." or ("File exited with code " .. code) })
  end)
end

vim.keymap.set("n", "<leader>rr", run_project, {
  desc = "Run project",
})

vim.keymap.set("n", "<leader>rf", run_file, {
  desc = "Run current file",
})

return {}
