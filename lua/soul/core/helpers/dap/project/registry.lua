local M = {}

local fn = vim.fn

local function registry_path(override)
	if override then
		return override
	end

	local directory = fn.stdpath("state") .. "/soul/dap"
	fn.mkdir(directory, "p")
	return directory .. "/projects.json"
end

local function read(file_path)
	if fn.filereadable(file_path) ~= 1 then
		return {}
	end

	local ok, data = pcall(vim.json.decode, table.concat(fn.readfile(file_path), "\n"))
	if not ok or type(data) ~= "table" then
		return nil, "invalid DAP project registry JSON"
	end

	return data
end

local function write(file_path, data)
	local ok, encoded = pcall(vim.json.encode, data)
	if not ok then
		return false, encoded
	end

	local temporary = file_path .. ".tmp"
	if fn.writefile({ encoded }, temporary) ~= 0 then
		return false, "could not write temporary DAP registry"
	end

	local renamed, rename_error = vim.uv.fs_rename(temporary, file_path)
	if not renamed then
		fn.delete(temporary)
		return false, rename_error
	end

	return true
end

function M.setup(path, override)
	local file_path = registry_path(override)
	fn.mkdir(fn.fnamemodify(file_path, ":h"), "p")

	local function get(root)
		local key = path.key(root)
		if not key then
			return nil
		end

		local data, read_error = read(file_path)
		if not data then
			return nil, read_error
		end

		return data[key]
	end

	local function list()
		local data, read_error = read(file_path)
		if not data then
			return nil, read_error
		end

		local entries = {}
		for _, entry in pairs(data) do
			if type(entry) == "table" and type(entry.root) == "string" then
				entries[#entries + 1] = entry
			end
		end

		table.sort(entries, function(a, b)
			return (a.last_opened or a.updated_at or 0) > (b.last_opened or b.updated_at or 0)
		end)

		return entries
	end

	local function update(root, fields)
		if type(fields) ~= "table" then
			return false, "DAP project fields must be a table"
		end

		root = path.normalize(root)
		local key = path.key(root)
		if not key then
			return false, "invalid DAP project root"
		end

		local data, read_error = read(file_path)
		if not data then
			return false, read_error
		end

		local entry = type(data[key]) == "table" and data[key] or { root = root, created_at = os.time() }
		for name, value in pairs(fields) do
			if name == "executable" and type(value) == "string" then
				value = path.normalize(value)
			end
			entry[name] = value
		end

		entry.root = root
		entry.updated_at = os.time()
		data[key] = entry

		return write(file_path, data)
	end

	local function touch(root)
		return update(root, { last_opened = os.time() })
	end

	return {
		get = get,
		list = list,
		update = update,
		touch = touch,
		path = file_path,
	}
end

return M
