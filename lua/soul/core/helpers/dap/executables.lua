local M = {}

local fn = vim.fn
local path = require("soul.core.helpers.dap.path")
local platform = require("soul.core.platform")

function M.find(root)
	root = path.normalize(root)
	if not root then
		return {}
	end

	local found = {}
	local seen = {}

	local function add(candidate)
		local executable = path.normalize(candidate)
		if not executable or not path.is_executable(executable) then
			return
		end

		local key = path.key(executable)
		if seen[key] then
			return
		end

		seen[key] = true
		found[#found + 1] = executable
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
			local candidate = directory .. "/" .. name

			if kind == "file" then
				add(candidate)
			elseif recursive and kind == "directory" and depth < 3 and not ignored_directories[name] then
				scan(candidate, depth + 1, true)
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
		local function rank(candidate)
			local lower = candidate:lower()
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
