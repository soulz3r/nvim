-- lua/soul/core/projects.lua
local M = {}

local paths = require("soul.core.paths")

local root_markers = {
  ".git",
  "CMakeLists.txt",
  "Makefile",
  "makefile",
  "Cargo.toml",
  "go.mod",
  "package.json",
  "build.bat",
  "build.sh",
  "compile_commands.json",
  "compile_flags.txt",
  "meson.build",
}

local function project_root(path)
  if path and path ~= "" then
    return vim.fn.fnamemodify(path, ":p")
  end

  local cwd = vim.fn.getcwd()
  return vim.fs.root(cwd, root_markers) or cwd
end

local function has_file(root, name)
  return vim.fn.filereadable(root .. "/" .. name) == 1
end

local function executable(name)
  return vim.fn.executable(name) == 1
end

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
      desc = "Close project output",
    })
  end

  return append
end

local function run_command(command, root, append, callback)
  append({ "", "$ " .. table.concat(command, " ") })

  local job = vim.fn.jobstart(command, {
    cwd = root,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          if #data > 0 then append(data) end
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          if #data > 0 then append(data) end
        end)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        callback(code)
      end)
    end,
  })

  if job <= 0 then
    append({ "Could not start process. jobstart returned " .. job })
    return false
  end

  return true
end

local function script_connector(root)
  local windows = paths.is_windows
  local script = windows and "build.bat" or "build.sh"

  if not has_file(root, script) then
    return nil
  end

  if windows then
    return {
      name = "Custom build script",
      build = {
        paths.pwsh,
        "-NoLogo",
        "-NoProfile",
        "-NonInteractive",
        "-Command",
        "& '.\\build.bat'; exit $LASTEXITCODE",
      },
    }
  end

  return {
    name = "Custom build script",
    build = { "bash", "./build.sh" },
  }
end

local function cmake_connector(root)
  if not has_file(root, "CMakeLists.txt") or not executable("cmake") then
    return nil
  end

  local build_dir = root .. "/build"

  return {
    name = "CMake",
    configure = { "cmake", "-S", root, "-B", build_dir },
    build = { "cmake", "--build", build_dir, "--config", "Debug" },
  }
end

local function make_connector(root)
  if not (has_file(root, "Makefile") or has_file(root, "makefile")) then
    return nil
  end

  local make = executable("make") and "make"
    or (paths.is_windows and executable("mingw32-make") and "mingw32-make")

  if not make then
    return nil
  end

  return {
    name = "Make",
    build = { make },
  }
end

local function cargo_connector(root)
  if not has_file(root, "Cargo.toml") or not executable("cargo") then
    return nil
  end

  return {
    name = "Cargo",
    build = { "cargo", "build" },
    run = { "cargo", "run" },
  }
end

local function go_connector(root)
  if not has_file(root, "go.mod") or not executable("go") then
    return nil
  end

  return {
    name = "Go",
    build = { "go", "build", "./..." },
    run = { "go", "run", "." },
  }
end

local function node_connector(root)
  if not has_file(root, "package.json") or not executable("npm") then
    return nil
  end

  local ok, package = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(root .. "/package.json"), "\n"))
  end)

  if not ok or type(package) ~= "table" or type(package.scripts) ~= "table" then
    return nil
  end

  local run_script = package.scripts.start and "start"
    or (package.scripts.dev and "dev")

  if not run_script and not package.scripts.build then
    return nil
  end

  return {
    name = "Node.js",
    build = package.scripts.build and { "npm", "run", "build" } or nil,
    run = run_script and { "npm", "run", run_script } or nil,
  }
end

function M.detect(root)
  root = project_root(root)

  local detectors = {
    script_connector,
    cmake_connector,
    make_connector,
    cargo_connector,
    go_connector,
    node_connector,
  }

  for _, detect in ipairs(detectors) do
    local connector = detect(root)
    if connector then
      return connector, root
    end
  end

  return nil, root
end

local function find_executables(root)
  local found = {}
  local search_dirs = {
    "bin",
    "build",
    "build/Debug",
    "build/Release",
    "Debug",
    "Release",
  }

  for _, directory in ipairs(search_dirs) do
    local full_path = root .. "/" .. directory

    if vim.fn.isdirectory(full_path) == 1 then
      local files = vim.fs.find(function(name, path)
        if path:find("CMakeFiles", 1, true)
          or path:find("Testing", 1, true)
        then
          return false
        end

        if paths.is_windows then
          return name:match("%.exe$") ~= nil
        end

        return true
      end, {
        path = full_path,
        type = "file",
        limit = 100,
      })

      for _, file in ipairs(files) do
        if executable(file) then
          found[#found + 1] = file
        end
      end
    end
  end

  return found
end

local function launch_project(root, append)
  local executables = find_executables(root)

  if #executables == 0 then
    append({ "", "Build succeeded, but no executable was found in bin/ or build/." })
    return
  end

  local function launch(file)
    run_command({ file }, root, append, function(code)
      append({
        "",
        code == 0 and "Project finished successfully."
          or ("Project exited with code " .. code),
      })
    end)
  end

  if #executables == 1 then
    launch(executables[1])
    return
  end

  vim.ui.select(executables, {
    prompt = "Select project executable:",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":.")
    end,
  }, function(choice)
    if choice then
      launch(choice)
    end
  end)
end

local function run_build_steps(connector, root, append, callback)
  local function build()
    if not connector.build then
      callback(false, "This project has no build command configured.")
      return
    end

    run_command(connector.build, root, append, function(code)
      if code == 0 then
        callback(true)
      else
        callback(false, "Build failed. Exit code: " .. code)
      end
    end)
  end

  if connector.configure then
    run_command(connector.configure, root, append, function(code)
      if code == 0 then
        build()
      else
        callback(false, "Project configuration failed. Exit code: " .. code)
      end
    end)
  else
    build()
  end
end

function M.build(root)
  local connector
  connector, root = M.detect(root)

  local append = open_output()
  if not connector then
    append({
      "No supported project build system found.",
      "Supported: build.bat/build.sh, CMake, Make, Cargo, Go, and npm.",
    })
    return
  end

  append({ "Project: " .. root, "Build system: " .. connector.name })

  run_build_steps(connector, root, append, function(ok, message)
    append({ "", ok and "Build succeeded." or message })
  end)
end

function M.run(root)
  local connector
  connector, root = M.detect(root)

  local append = open_output()
  if not connector then
    append({
      "No supported project runner found.",
      "Supported: build.bat/build.sh, CMake, Make, Cargo, Go, and npm.",
    })
    return
  end

  append({ "Project: " .. root, "Project type: " .. connector.name })

  if connector.run then
    run_command(connector.run, root, append, function(code)
      append({
        "",
        code == 0 and "Project finished successfully."
          or ("Project exited with code " .. code),
      })
    end)
    return
  end

  run_build_steps(connector, root, append, function(ok, message)
    if not ok then
      append({ "", message })
      return
    end

    append({ "", "Build succeeded. Launching project..." })
    launch_project(root, append)
  end)
end

function M.run_file()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" then
    vim.notify("Current buffer has no file", vim.log.levels.WARN)
    return
  end

  local root = vim.fn.fnamemodify(file, ":h")
  local extension = vim.fn.fnamemodify(file, ":e"):lower()
  local command

  if extension == "c" then
    local compiler = vim.fn.exepath("clang")
    if compiler == "" then
      compiler = vim.fn.exepath("gcc")
    end

    if compiler == "" then
      vim.notify("No C compiler found (clang or gcc)", vim.log.levels.ERROR)
      return
    end

    local output = vim.fn.stdpath("cache")
      .. "/project-file-"
      .. vim.fn.sha256(file):sub(1, 12)
      .. (paths.is_windows and ".exe" or "")

    local append = open_output()
    command = { compiler, "-std=c23", "-g", file, "-o", output }

    run_command(command, root, append, function(code)
      if code ~= 0 then
        append({ "", "Compilation failed. Exit code: " .. code })
        return
      end

      run_command({ output }, root, append, function(run_code)
        append({
          "",
          run_code == 0 and "File finished successfully."
            or ("File exited with code " .. run_code),
        })
      end)
    end)
    return
  elseif extension == "lua" then
    command = { vim.fn.exepath("lua"), file }
  elseif extension == "py" then
    local python = vim.fn.exepath("python")
    if python == "" then
      python = vim.fn.exepath("python3")
    end
    command = { python, file }
  elseif extension == "js" then
    command = { vim.fn.exepath("node"), file }
  end

  if not command or command[1] == "" then
    vim.notify("No file runner configured for ." .. extension, vim.log.levels.WARN)
    return
  end

  local append = open_output()
  run_command(command, root, append, function(code)
    append({
      "",
      code == 0 and "File finished successfully."
        or ("File exited with code " .. code),
    })
  end)
end

return M
