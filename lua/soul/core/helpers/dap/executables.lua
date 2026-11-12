local M = {}

local fn = vim.fn
local platform = require("soul.core.platform")

local function normalize(path)
	if type(path) ~= "string" or path == "" then
		return nil
	end

	local normalized = fn.fnamemodify(fn.resolve(path), ":p"):gsub("\\", "/")
	if normalized == "/" or normalized:match("^%a:/$") then
		return normalized
	end

	return (normalized:gsub("/+$", ""))
end

local function is_executable(path)
	return type(path) == "string" and path ~= "" and fn.executable(path) == 1
end

function M.find(root)
	root = normalize(root)
	if not root then
		return {}
	end

	local found = {}
	local seen = {}

	local function add(path)
		local executable = normalize(path)
		if not executable or not is_executable(executable) then
			return
		end

		local key = platform.is_windows and executable:lower() or executable
		if seen[key] then
			return
		end

		seen[key] = true
		table.insert(found, executable)
	end

	local ignored_directories = {
		[".git"] = true,
		["node_modules"] = true,
		[".venv"] = true,
		["venv"] = true,
	}

	local function scan(directory, depth, recursive)
		if fn.isdirectory(directory) ~= 1 then
			return
		end

		local ok, entries = pcall(vim.fs.dir, directory)
		if not ok then
			return
		end

		for name, kind in entries do
			local path = directory .. "/" .. name

			if kind == "file" then
				add(path)
			elseif recursive and kind == "directory" and depth < 3 and not ignored_directories[name] then
				scan(path, depth + 1, true)
			end
		end
	end

	-- Root-level files are cheap to inspect. Search common output directories
	-- recursively, but keep traversal bounded and avoid dependency trees.
	scan(root, 0, false)
	for _, directory in ipairs({
		root .. "/bin",
		root .. "/build",
		root .. "/Debug",
		root .. "/Release",
	}) do
		scan(directory, 0, true)
	end

	table.sort(found, function(a, b)
		local function rank(path)
			local lower = path:lower()

			if lower:find("/bin/", 1, true) or lower:find("\\bin\\", 1, true) then
				return 1
			elseif lower:find("/build/", 1, true) or lower:find("\\build\\", 1, true) then
				return 2
			end

			return 3
		end

		local rank_a, rank_b = rank(a), rank(b)
		if rank_a ~= rank_b then
			return rank_a < rank_b
		end

		return a:lower() < b:lower()
	end)

	return found
end

return M
