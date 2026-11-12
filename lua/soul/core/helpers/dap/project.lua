local M = {}

local fn = vim.fn
local path = require("soul.core.helpers.dap.path")
local find_executables = require("soul.core.helpers.dap.executables").find

local root_markers = {
	".git",
	".clangd",
	".clang-tidy",
	".clang-format",
	"CMakeLists.txt",
	"Makefile",
	"makefile",
	"build.ninja",
	"compile_commands.json",
	"compile_flags.txt",
	"meson.build",
	"Cargo.toml",
	"build.sh",
	"build.bat",
	"build_all.sh",
	"build_all.bat",
}

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

function M.setup(project_registry)
	local projects = {}
	local selected_project

	local legacy_state_files = {
		fn.stdpath("config") .. "/lsp/dap-projects.json",
		fn.stdpath("state") .. "/soul/dap-projects.json",
	}

	local registry_migration = require("soul.core.helpers.dap.registry")
	for _, legacy_path in ipairs(legacy_state_files) do
		registry_migration.migrate_file(legacy_path, project_registry, path.normalize)
	end

	local function load_projects()
		local ok, entries = pcall(project_registry.list)
		if not ok or type(entries) ~= "table" then
			vim.notify("Could not read the YAP project registry: " .. tostring(entries), vim.log.levels.ERROR)
			return {}
		end

		local loaded = {}
		for _, entry in ipairs(entries) do
			if type(entry) == "table" and type(entry.root) == "string" then
				local root = path.normalize(entry.root)
				local executable = entry.debug_executable or entry.last_executable
				local key = path.key(root)

				if key and (entry.dap_enabled or executable or type(entry.dap_args) == "table") then
					loaded[key] = {
						root = root,
						executable = path.normalize(executable),
						args = copy_args(entry.dap_args),
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
			fields.debug_executable = normalized_executable
			fields.last_executable = normalized_executable
		end

		local ok, saved = pcall(project_registry.update, root, fields)
		if not ok or saved ~= true then
			vim.notify(
				"Could not save DAP project metadata for:\n" .. root .. (not ok and ("\n" .. tostring(saved)) or ""),
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
		local ok, saved = pcall(project_registry.update, root, {
			dap_enabled = true,
			dap_args = normalized_args,
		})

		if not ok or saved ~= true then
			vim.notify(
				"Could not save launch arguments for project:\n" .. root .. (not ok and ("\n" .. tostring(saved)) or ""),
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

		-- Refresh shared metadata so projects added by YAP or another Neovim
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

	local function resolve_root()
		if selected_project then
			if selected_project.buf == vim.api.nvim_get_current_buf() then
				return selected_project.root
			end
			selected_project = nil
		end

		local name = vim.api.nvim_buf_get_name(0)
		if name ~= "" then
			local file = path.normalize(name)
			local detected = vim.fs.root(0, root_markers)
			if detected then
				return path.normalize(detected)
			end

			local registered = find_registered_ancestor(file)
			if registered then
				return path.normalize(registered)
			end

			return path.normalize(fn.fnamemodify(file, ":h"))
		end

		local cwd = path.normalize(fn.getcwd())
		local detected = vim.fs.root(cwd, root_markers)
		if detected then
			return path.normalize(detected)
		end
		return find_registered_ancestor(cwd) or cwd
	end

	local function current()
		local root = resolve_root()
		if not root then
			return nil, nil
		end

		local key = path.key(root)
		local entry = key and projects[key] or nil
		local ok, shared = pcall(project_registry.get, root)

		if
			ok
			and type(shared) == "table"
			and (
				shared.dap_enabled
				or shared.debug_executable
				or shared.last_executable
				or type(shared.dap_args) == "table"
			)
		then
			entry = entry or { root = root }
			entry.executable = shared.debug_executable or shared.last_executable or entry.executable
			if type(shared.dap_args) == "table" then
				entry.args = copy_args(shared.dap_args)
			end
			projects[key] = entry
		end

		return entry or { root = root, executable = nil }, root
	end

	local function select_project()
		local current_key = path.key(resolve_root())
		projects = load_projects()
		local entries = {}

		for key, entry in pairs(projects) do
			if type(entry) == "table" and entry.root then
				entries[#entries + 1] = {
					key = key,
					root = entry.root,
					executable = entry.executable or "",
				}
			end
		end

		table.sort(entries, function(a, b)
			return a.root:lower() < b.root:lower()
		end)

		if #entries == 0 then
			vim.notify("No saved DAP projects were found in the YAP project registry.", vim.log.levels.WARN)
			return
		end

		local choices = {}
		for _, entry in ipairs(entries) do
			choices[#choices + 1] = entry.root .. (entry.key == current_key and " [active]" or "")
		end

		vim.ui.select(choices, {
			prompt = "Select saved DAP project",
		}, function(_, index)
			if not index then
				return
			end

			local entry = entries[index]
			if fn.isdirectory(entry.root) ~= 1 then
				vim.notify("Project directory does not exist:\n" .. entry.root, vim.log.levels.ERROR)
				return
			end

			vim.api.nvim_set_current_dir(entry.root)
			selected_project = {
				root = entry.root,
				buf = vim.api.nvim_get_current_buf(),
			}

			local touched, saved = pcall(project_registry.touch, entry.root)
			if not touched or saved ~= true then
				vim.notify(
					"Changed project directory, but could not update its last-opened metadata.",
					vim.log.levels.WARN
				)
			end

			vim.notify(
				"Selected project:\n"
					.. entry.root
					.. "\nExecutable: "
					.. (entry.executable ~= "" and entry.executable or "Not configured"),
				vim.log.levels.INFO,
				{ title = "DAP" }
			)
		end)
	end

	local function select_executable()
		local entry, root = current()
		if not entry or not root then
			vim.notify("Could not resolve the current project's root.", vim.log.levels.ERROR)
			return
		end

		vim.ui.input({
			prompt = "Full executable path: ",
			default = entry.executable or "",
			completion = "file",
		}, function(input)
			if not input or input == "" then
				return
			end

			input = input:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
			local executable = path.normalize(input)
			if not path.is_executable(executable) then
				vim.notify("Executable not found:\n" .. tostring(executable), vim.log.levels.ERROR)
				return
			end

			if not save_executable(root, executable) then
				return
			end
			vim.notify("Executable saved for:\n" .. root .. "\n" .. executable, vim.log.levels.INFO, { title = "DAP" })
		end)
	end

	vim.api.nvim_create_autocmd("BufEnter", {
		group = vim.api.nvim_create_augroup("SoulDapProjectSelection", { clear = true }),
		callback = function(args)
			if selected_project and args.buf ~= selected_project.buf then
				selected_project = nil
			end
		end,
	})

	return {
		current = current,
		resolve_root = resolve_root,
		select = select_project,
		select_executable = select_executable,
		save_executable = save_executable,
		save_args = save_args,
		find_executables = find_executables,
		is_executable = path.is_executable,
	}
end

return M
