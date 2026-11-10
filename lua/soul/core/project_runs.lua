-- lua/soul/core/project_runs.lua
local M = {}

local storage = vim.fn.stdpath("data") .. "/soul/project-runs.json"

local function normalize(path)
	path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
	path = path:gsub("\\", "/")

	if vim.fn.has("win32") == 1 then
		path = path:lower()
	end

	return path
end

local function read_data()
	local lines = vim.fn.readfile(storage)
	if #lines == 0 then
		return {}
	end

	local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok or type(data) ~= "table" then
		return {}
	end

	return data
end

local function write_data(data)
	local directory = vim.fn.fnamemodify(storage, ":h")
	vim.fn.mkdir(directory, "p")

	local temporary = storage .. ".tmp"
	local result = vim.fn.writefile({ vim.json.encode(data) }, temporary)

	if result ~= 0 then
		vim.notify("Could not save project run configuration.", vim.log.levels.ERROR)
		return false
	end

	if vim.fn.rename(temporary, storage) ~= 0 then
		vim.fn.delete(temporary)
		vim.notify("Could not replace project run configuration.", vim.log.levels.ERROR)
		return false
	end

	return true
end

local function executable_key(root, executable)
	local normalized_root = normalize(root):gsub("/$", "")
	local normalized_executable = normalize(executable)

	return normalized_executable:sub(#normalized_root + 2)
end

function M.get(root, executable)
	local data = read_data()
	local project = data[normalize(root)]

	if type(project) ~= "table" then
		return ""
	end

	local args = project[executable_key(root, executable)]
	return type(args) == "string" and args or ""
end

function M.set(root, executable, args)
	local data = read_data()
	local project_key = normalize(root)
	local key = executable_key(root, executable)

	data[project_key] = type(data[project_key]) == "table" and data[project_key] or {}
	data[project_key][key] = args

	return write_data(data)
end

return M
