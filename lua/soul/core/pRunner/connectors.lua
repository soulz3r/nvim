-- lua/soul/core/pRunner/connectors.lua
local M = {}

local function executable(name)
  return vim.fn.executable(name) == 1
end

local function has_file(root, name)
  return vim.fn.filereadable(root .. "/" .. name) == 1
end

local function command_exists(root, name)
  return vim.fn.executable(root .. "/" .. name) == 1
end

local function script_connector(root)
  local windows = vim.fn.has("win32") == 1
  local script = windows and "build.bat" or "build.sh"

  if not has_file(root, script) then
    return nil
  end

  if windows then
    local pwsh = require("soul.core.paths").pwsh
    return {
      name = "Custom build script",
      build = { pwsh, "-NoLogo", "-NoProfile", "-NonInteractive", "-Command",
        "& '.\\build.bat'; exit $LASTEXITCODE" },
      run_after_build = true,
    }
  end

  return {
    name = "Custom build script",
    build = { "bash", "./build.sh" },
    run_after_build = true,
  }
end

local function cmake_connector(root)
  if not has_file(root, "CMakeLists.txt") or not executable("cmake") then
    return nil
  end

  local build_dir = root .. "/build"
  return {
    name = "CMake",
    build = { "cmake", "--build", build_dir, "--config", "Debug" },
    configure = { "cmake", "-S", root, "-B", build_dir },
    run_after_build = true,
  }
end

local function make_connector(root)
  if not (has_file(root, "Makefile") or has_file(root, "makefile")) then
    return nil
  end

  local make = executable("make") and "make" or (vim.fn.has("win32") == 1 and "mingw32-make" or nil)
  if not make or not executable(make) then
    return nil
  end

  return {
    name = "Make",
    build = { make },
    run_after_build = true,
  }
end

local function cargo_connector(root)
  if has_file(root, "Cargo.toml") and executable("cargo") then
    return {
      name = "Cargo",
      run = { "cargo", "run" },
    }
  end
end

local function go_connector(root)
  if has_file(root, "go.mod") and executable("go") then
    return {
      name = "Go",
      run = { "go", "run", "." },
    }
  end
end

local function node_connector(root)
  if not has_file(root, "package.json") then
    return nil
  end

  local package_file = root .. "/package.json"
  local ok, package = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(package_file), "\n"))
  end)

  if not ok or type(package) ~= "table" or type(package.scripts) ~= "table" then
    return nil
  end

  local script = package.scripts.start and "start"
    or package.scripts.dev and "dev"

  if script and executable("npm") then
    return {
      name = "Node.js",
      run = { "npm", "run", script },
    }
  end
end

M.detect = function(root)
  local connectors = {
    script_connector,
    cmake_connector,
    make_connector,
    cargo_connector,
    go_connector,
    node_connector,
  }

  for _, detect in ipairs(connectors) do
    local connector = detect(root)
    if connector then
      return connector
    end
  end
end

return M
