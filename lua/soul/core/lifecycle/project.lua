local M = {}

local function read_lines(path)
	if vim.fn.filereadable(path) ~= 1 then
		return nil
	end

	local ok, lines = pcall(vim.fn.readfile, path)
	return ok and lines or nil
end

local function read_registry(path)
	local lines = read_lines(path)
	if not lines then
		return nil
	end

	local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok or type(data) ~= "table" then
		return nil
	end

	return data
end

local function decode_project_line(line)
	local fields = {}
	local field = {}
	local escaped = false

	for index = 1, #line do
		local char = line:sub(index, index)

		if escaped then
			if char == "n" then
				field[#field + 1] = "\n"
			elseif char == "\\" or char == "=" then
				field[#field + 1] = char
			else
				field[#field + 1] = "\\" .. char
			end
			escaped = false
		elseif char == "\\" then
			escaped = true
		elseif char == "=" then
			fields[#fields + 1] = table.concat(field)
			field = {}
		else
			field[#field + 1] = char
		end
	end

	if escaped then
		field[#field + 1] = "\\"
	end
	fields[#fields + 1] = table.concat(field)

	if type(fields[2]) ~= "string" or fields[2] == "" then
		return nil
	end

	return {
		path = fields[2],
		activated = tonumber(fields[4]) or 1,
		last_accessed_time = tonumber(fields[5]) or 0,
	}
end

local function select_recent_project(entries, path_field, active_field, time_field)
	local selected
	local selected_time = -1

	for _, entry in pairs(entries or {}) do
		if type(entry) == "table" then
			local root = entry[path_field]
			local active = active_field and tonumber(entry[active_field]) or 1
			local timestamp_value = entry[time_field]
			if timestamp_value == nil then
				timestamp_value = entry.updated_at
			end
			local timestamp = tonumber(timestamp_value) or 0

			if
				type(root) == "string"
				and root ~= ""
				and active == 1
				and vim.fn.isdirectory(root) == 1
				and timestamp > selected_time
			then
				selected = vim.fs.normalize(root)
				selected_time = timestamp
			end
		end
	end

	return selected
end

local function restore_telescope_projects(path)
	local lines = read_lines(path)
	if not lines then
		return nil
	end

	local projects = {}
	for _, line in ipairs(lines) do
		local project = decode_project_line(line)
		if project then
			projects[#projects + 1] = project
		end
	end

	return select_recent_project(projects, "path", "activated", "last_accessed_time")
end

local function restore_yap_registry(path)
	local registry = read_registry(path)
	if not registry then
		return nil
	end

	return select_recent_project(registry, "root", nil, "last_opened")
end

function M.restore(path)
	local selected

	if path then
		if path:match("%.json$") then
			selected = restore_yap_registry(path)
		else
			selected = restore_telescope_projects(path)
		end
	else
		selected = restore_telescope_projects(vim.fn.stdpath("data") .. "/telescope-projects.txt")

		if not selected then
			local state = vim.fn.stdpath("state")
			selected = restore_yap_registry(state .. "/yap/projects.json")
			if not selected then
				selected = restore_yap_registry(state .. "/soul/projects.json")
			end
		end
	end

	if not selected then
		return false
	end

	local ok = pcall(vim.cmd.cd, vim.fn.fnameescape(selected))
	return ok
end

function M.setup()
	local group = vim.api.nvim_create_augroup("SoulProjectRestore", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		once = true,
		callback = function()
			pcall(vim.api.nvim_del_augroup_by_id, group)

			-- Never override an explicit file or directory supplied by the user.
			if vim.fn.argc() ~= 0 then
				return
			end

			vim.schedule(M.restore)
		end,
	})
end

return M
