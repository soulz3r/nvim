local M = {}

local fn = vim.fn

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

function M.setup(path, project_registry)
	local owns_registry = project_registry == nil
	project_registry = project_registry or require("soul.core.helpers.dap.project.registry").setup(path)

	if owns_registry then
		local registry_migration = require("soul.core.helpers.dap.registry")
		local state_dir = fn.stdpath("state") .. "/soul/dap"
		local yap_registry_path = fn.stdpath("state") .. "/yap/projects.json"

		if fn.filereadable(yap_registry_path) ~= 1 then
			yap_registry_path = fn.stdpath("state") .. "/soul/projects.json"
		end

		registry_migration.import_yap_file(
			yap_registry_path,
			project_registry,
			path.normalize,
			state_dir .. "/yap-registry-imported"
		)

		local legacy_state_files = {
			fn.stdpath("config") .. "/lsp/dap-projects.json",
			fn.stdpath("state") .. "/soul/dap-projects.json",
		}

		for _, legacy_path in ipairs(legacy_state_files) do
			registry_migration.migrate_file(legacy_path, project_registry, path.normalize)
		end
	end

	local projects = {}

	local function load_projects()
		local ok, entries, read_error = pcall(project_registry.list)
		if not ok or type(entries) ~= "table" then
			local detail = not ok and entries or read_error or entries
			vim.notify(
				"Could not read the independent DAP project registry: " .. tostring(detail),
				vim.log.levels.ERROR
			)
			return {}
		end

		local loaded = {}
		for _, entry in ipairs(entries) do
			if type(entry) == "table" and type(entry.root) == "string" then
				local root = path.normalize(entry.root)
				local executable = entry.executable or entry.debug_executable or entry.last_executable
				local args = entry.args or entry.dap_args
				local key = path.key(root)

				if key and (entry.dap_enabled or executable or type(args) == "table") then
					loaded[key] = {
						root = root,
						executable = path.normalize(executable),
						args = copy_args(args),
					}
				end
			end
		end

		return loaded
	end

	projects = load_projects()

	local function save_executable(root, executable)
		root = path.normalize(root)
		local key = path.key(root)
		local normalized_executable = executable ~= nil and path.normalize(executable) or nil

		if not key or (executable ~= nil and not normalized_executable) then
			return nil
		end

		local fields = { dap_enabled = true }
		if normalized_executable then
			fields.executable = normalized_executable
		end

		local ok, saved, save_error = pcall(project_registry.update, root, fields)
		if not ok or saved ~= true then
			local detail = not ok and saved or save_error
			vim.notify(
				"Could not save DAP project metadata for:\n" .. root .. (detail and ("\n" .. tostring(detail)) or ""),
				vim.log.levels.ERROR
			)
			return nil
		end

		local entry = projects[key] or { root = root }
		entry.root = root
		if normalized_executable then
			entry.executable = normalized_executable
		end
		projects[key] = entry
		return entry
	end

	local function save_args(root, args)
		root = path.normalize(root)
		local key = path.key(root)
		if not key then
			return false
		end

		local normalized_args = copy_args(args)
		local ok, saved, save_error = pcall(project_registry.update, root, {
			dap_enabled = true,
			args = normalized_args,
		})

		if not ok or saved ~= true then
			local detail = not ok and saved or save_error
			vim.notify(
				"Could not save launch arguments for project:\n" .. root .. (detail and ("\n" .. tostring(detail)) or ""),
				vim.log.levels.ERROR
			)
			return false
		end

		local entry = projects[key] or { root = root }
		entry.args = normalized_args
		projects[key] = entry
		return true
	end

	local function find_registered_ancestor(candidate)
		if not candidate then
			return nil
		end

		-- Refresh DAP-owned metadata so projects added by another Neovim
		-- instance are visible without restarting this session.
		projects = load_projects()

		local best_root
		local best_length = -1
		for _, entry in pairs(projects) do
			if entry.root and path.is_within(candidate, entry.root) and #entry.root > best_length then
				best_root = entry.root
				best_length = #entry.root
			end
		end
		return best_root
	end

	local function current(root)
		root = path.normalize(root)
		if not root then
			return nil, nil
		end

		local key = path.key(root)
		local entry = key and projects[key] or nil
		local ok, shared = pcall(project_registry.get, root)

		if ok and type(shared) == "table" and (shared.dap_enabled or shared.executable or type(shared.args) == "table") then
			entry = entry or { root = root }
			entry.executable = shared.executable or entry.executable
			if type(shared.args) == "table" then
				entry.args = copy_args(shared.args)
			end
			projects[key] = entry
		end

		return entry or { root = root, executable = nil }, root
	end

	local function list()
		projects = load_projects()
		return projects
	end

	local function touch(root)
		return pcall(project_registry.touch, root)
	end

	return {
		current = current,
		list = list,
		save_executable = save_executable,
		save_args = save_args,
		find_registered_ancestor = find_registered_ancestor,
		touch = touch,
	}
end

return M
