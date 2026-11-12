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

-- Import one legacy DAP registry and retain its original file as a backup.
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
	local failed = false

	for key, entry in pairs(entries) do
		if type(entry) == "table" then
			local root = normalize(entry.root or key)
			if root then
				local fields = { dap_enabled = true }
				local executable = normalize(entry.executable)

				if executable then
					fields.debug_executable = executable
					fields.last_executable = executable
				end

				local ok, saved = pcall(project_registry.update, root, fields)
				if not ok or saved ~= true then
					failed = true
					vim.notify("Could not migrate DAP project metadata for:\n" .. root, vim.log.levels.ERROR)
				end
			end
		end
	end

	if failed then
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
		"Migrated DAP project settings into the YAP project registry. Backup:\n" .. backup,
		vim.log.levels.INFO,
		{ title = "DAP Registry" }
	)

	return true, backup
end

return M
