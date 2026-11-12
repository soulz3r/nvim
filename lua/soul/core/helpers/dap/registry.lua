local M = {}

local fn = vim.fn

local function read_json(path)
	local file = io.open(path, "r")
	if not file then
		return nil, "could not open file"
	end

	local content = file:read("*a")
	file:close()

	local ok, data = pcall(fn.json_decode, content)
	if not ok or type(data) ~= "table" then
		return nil, "invalid JSON"
	end

	return data
end

local function copy_args(args)
	local result = {}
	if type(args) == "table" then
		for _, arg in ipairs(args) do
			if type(arg) == "string" then
				result[#result + 1] = arg
			end
		end
	end
	return result
end

local function migrate_entries(entries, project_registry, normalize, legacy_shape)
	local failed = false

	for key, entry in pairs(entries) do
		if type(entry) == "table" then
			local root = normalize(entry.root or key)
			local executable = normalize(
				legacy_shape and entry.executable
					or (entry.debug_executable or entry.last_executable or entry.executable)
			)
			local args = legacy_shape and entry.args or (entry.dap_args or entry.args)
			local has_dap_data = legacy_shape or entry.dap_enabled or executable or type(args) == "table"

			if root and has_dap_data then
				local fields = { dap_enabled = true }
				if executable then
					fields.executable = executable
				end
				if type(args) == "table" then
					fields.args = copy_args(args)
				end

				local ok, saved = pcall(project_registry.update, root, fields)
				if not ok or saved ~= true then
					failed = true
					vim.notify("Could not migrate DAP project metadata for:\n" .. root, vim.log.levels.ERROR)
				end
			end
		end
	end

	return not failed
end

-- Import an older standalone DAP registry and retain its original file as a backup.
-- The source is moved only after every valid project entry was saved.
function M.migrate_file(path, project_registry, normalize)
	if fn.filereadable(path) ~= 1 then
		return true
	end

	local raw_data, read_error = read_json(path)
	if not raw_data then
		vim.notify("Could not migrate DAP registry (" .. read_error .. "):\n" .. path, vim.log.levels.ERROR)
		return false, read_error
	end

	local entries = type(raw_data.projects) == "table" and raw_data.projects or raw_data
	if not migrate_entries(entries, project_registry, normalize, true) then
		return false, "one or more project entries could not be saved"
	end

	local backup = path .. ".migrated"
	local suffix = 0
	while fn.filereadable(backup) == 1 do
		suffix = suffix + 1
		backup = path .. ".migrated." .. os.time() .. "." .. suffix
	end

	local moved, move_error = vim.uv.fs_rename(path, backup)
	if not moved then
		vim.notify(
			"Imported DAP settings, but could not move the old registry to a backup:\n" .. tostring(move_error),
			vim.log.levels.WARN
		)
		return false, move_error
	end

	vim.notify(
		"Migrated legacy DAP settings into the independent DAP registry. Backup:\n" .. backup,
		vim.log.levels.INFO,
		{ title = "DAP Registry" }
	)

	return true, backup
end

-- Import only DAP-owned fields from YAP's former shared registry.
-- The YAP file is deliberately left untouched because YAP still owns its project data.
function M.import_yap_file(path, project_registry, normalize, marker_path)
	if marker_path and fn.filereadable(marker_path) == 1 then
		return true
	end

	if fn.filereadable(path) ~= 1 then
		return true
	end

	local raw_data, read_error = read_json(path)
	if not raw_data then
		vim.notify("Could not import legacy DAP settings (" .. read_error .. "):\n" .. path, vim.log.levels.ERROR)
		return false, read_error
	end

	local entries = type(raw_data.projects) == "table" and raw_data.projects or raw_data
	if not migrate_entries(entries, project_registry, normalize, false) then
		return false, "one or more legacy DAP entries could not be imported"
	end

	if marker_path then
		fn.mkdir(fn.fnamemodify(marker_path, ":h"), "p")
		if fn.writefile({ tostring(os.time()) }, marker_path) ~= 0 then
			vim.notify(
				"Imported DAP settings, but could not write the migration marker:\n" .. marker_path,
				vim.log.levels.WARN
			)
			return false, "could not write migration marker"
		end
	end

	vim.notify(
		"Imported existing DAP executable and argument settings into the independent DAP registry.",
		vim.log.levels.INFO,
		{ title = "DAP Registry" }
	)

	return true
end

return M
