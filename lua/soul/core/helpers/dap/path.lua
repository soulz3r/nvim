local M = {}

local fn = vim.fn
local platform = require("soul.core.platform")

function M.normalize(path)
	if type(path) ~= "string" or path == "" then
		return nil
	end

	local normalized = fn.fnamemodify(fn.resolve(path), ":p"):gsub("\\", "/")

	if normalized == "/" or normalized:match("^%a:/$") then
		return normalized
	end

	return (normalized:gsub("/+$", ""))
end

function M.key(path)
	local normalized = M.normalize(path)
	if not normalized then
		return nil
	end

	return platform.is_windows and normalized:lower() or normalized
end

function M.is_executable(path)
	return type(path) == "string" and path ~= "" and fn.executable(path) == 1
end

function M.is_within(path, root)
	path = M.key(path)
	root = M.key(root)

	if not path or not root then
		return false
	end

	if path == root then
		return true
	end

	local prefix = root:sub(-1) == "/" and root or (root .. "/")
	return path:sub(1, #prefix) == prefix
end

return M
