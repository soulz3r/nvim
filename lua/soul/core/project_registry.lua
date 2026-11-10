local M = {}

local function registry_path()
  local directory = vim.fn.stdpath("state") .. "/soul"
  vim.fn.mkdir(directory, "p")
  return directory .. "/projects.json"
end

local function normalize(root)
  root = vim.fs.normalize(vim.fn.fnamemodify(root, ":p"))
  return vim.fn.has("win32") == 1 and root:lower() or root
end

local function read()
  local path = registry_path()
  if vim.fn.filereadable(path) ~= 1 then return {} end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(data) ~= "table" then return {} end
  return data
end

local function write(data)
  local path = registry_path()
  local temporary = path .. ".tmp"
  local ok, encoded = pcall(vim.json.encode, data)
  if not ok then return false end
  if vim.fn.writefile({ encoded }, temporary) ~= 0 then return false end
  local renamed = vim.uv.fs_rename(temporary, path)
  return renamed == true
end

function M.get(root)
  if type(root) ~= "string" or root == "" then return nil end
  return read()[normalize(root)]
end

function M.update(root, fields)
  if type(root) ~= "string" or root == "" or type(fields) ~= "table" then return false end
  local data = read()
  local key = normalize(root)
  local entry = data[key] or { root = key, created_at = os.time() }
  for name, value in pairs(fields) do entry[name] = value end
  entry.root = key
  entry.updated_at = os.time()
  data[key] = entry
  return write(data)
end

function M.list()
  local entries = {}
  for _, entry in pairs(read()) do
    if type(entry) == "table" and type(entry.root) == "string" then
      entries[#entries + 1] = entry
    end
  end
  table.sort(entries, function(a, b)
    return (a.last_opened or a.updated_at or 0) > (b.last_opened or b.updated_at or 0)
  end)
  return entries
end

function M.status(root)
  root = root or vim.fn.getcwd()
  local markers = { ".git", "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", "build.sh", "build.bat" }
  local directory = vim.fn.isdirectory(root) == 1 and root or vim.fs.dirname(root)
  local project = vim.fs.root(directory, markers)
  if not project then return "" end
  return "󰉋 " .. vim.fn.fnamemodify(project, ":t")
end

function M.touch(root)
  return M.update(root, { last_opened = os.time() })
end

return M
