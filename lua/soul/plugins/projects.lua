-- lua/soul/plugins/projects.lua
local M = {
	"nvim-telescope/telescope-project.nvim",

	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
}

function M.config()
	local telescope = require("telescope")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local finders = require("telescope.finders")
	local pickers = require("telescope.pickers")
	local conf = require("telescope.config").values
	local themes = require("telescope.themes")
	local projects = require("soul.core.projects")

	local function argument_history(root, executable)
		local directory = vim.fn.stdpath("data") .. "/soul/argument-history"
		vim.fn.mkdir(directory, "p")

		local key = vim.fn.sha256(root .. "\\0" .. executable)
		local path = directory .. "/" .. key .. ".txt"
		local history = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}

		return path, history
	end

	local function save_argument(path, history, input)
		if input == "" then
			return
		end

		history = vim.tbl_filter(function(value)
			return value ~= input
		end, history)
		table.insert(history, input)

		while #history > 100 do
			table.remove(history, 1)
		end

		vim.fn.writefile(history, path)
	end

	local function prompt_arguments(root, executable, build_first)
		local history_path, history = argument_history(root, executable)
		local suggestions = {}

		for index = #history, 1, -1 do
			table.insert(suggestions, history[index])
		end

		pickers.new(themes.get_dropdown({}), {
			prompt_title = "Arguments: " .. vim.fn.fnamemodify(executable, ":t"),
			finder = finders.new_table({
				results = suggestions,
			}),
			sorter = conf.generic_sorter({}),
			previewer = false,
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					local input = action_state.get_current_line()

					if input == "" and entry then
						input = entry.value
					end

					local selected_history = entry and input == entry.value
					local args, err = projects.parse_args(input)

					if not args then
						vim.notify(err, vim.log.levels.ERROR)
						return
					end

					if not selected_history then
						save_argument(history_path, history, input)
					end

					actions.close(prompt_bufnr)

					vim.schedule(function()
						if build_first then
							projects.run(root, args)
						else
							projects.run_binary(executable, root, args)
						end
					end)
				end)

				return true
			end,
		}):find()
	end

	local function open_executable_picker(path)
		local root, executables = projects.list_executables(path)

		if #executables == 0 then
			vim.notify("No executables found in " .. root .. "/bin", vim.log.levels.WARN)
			return
		end

		pickers.new(themes.get_dropdown({}), {
			prompt_title = "Project Executables",
			finder = finders.new_table({
				results = executables,
				entry_maker = function(file)
					local name = vim.fn.fnamemodify(file, ":t")
					local relative = "bin/" .. name

					return {
						value = file,
						ordinal = name .. " " .. relative,
						display = name,
						filename = file,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = false,
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()

					if not entry then
						return
					end

					actions.close(prompt_bufnr)

					vim.schedule(function()
						prompt_arguments(root, entry.value)
					end)
				end)

				return true
			end,
		}):find()
	end

	local function open_project_run_picker(path)
		local root = projects.get_root(path)
		local executable = projects.project_executable(root)

		prompt_arguments(root, executable, true)
	end

	local function with_project(prompt_bufnr, callback)
		local entry = action_state.get_selected_entry()

		if not entry or type(entry.value) ~= "string" or entry.value == "" then
			return
		end

		local path = entry.value
		actions.close(prompt_bufnr)

		vim.schedule(function()
			vim.cmd.cd(vim.fn.fnameescape(path))
			callback(path)
		end)
	end

	local function run_project(prompt_bufnr)
		with_project(prompt_bufnr, open_project_run_picker)
	end

	local function build_project(prompt_bufnr)
		with_project(prompt_bufnr, projects.build)
	end

	local function select_project_executable(prompt_bufnr)
		with_project(prompt_bufnr, open_executable_picker)
	end

	local function clean_project(prompt_bufnr)
		with_project(prompt_bufnr, projects.clean)
	end

	local function rebuild_project(prompt_bufnr)
		with_project(prompt_bufnr, projects.rebuild)
	end

	telescope.setup({
		extensions = {
			project = {
				base_dirs = {
					require("soul.core.paths").projects,
				},
				ignore_missing_dirs = true,
				hidden_files = true,
				order_by = "recent",
				search_by = { "title", "path" },
				theme = "dropdown",
				on_project_selected = function(prompt_bufnr)
					require("telescope._extensions.project.actions")
						.change_working_directory(prompt_bufnr, false)
				end,
				mappings = {
					i = {
						["<C-g>"] = run_project,
						["<C-y>"] = build_project,
						["<C-e>"] = select_project_executable,
					},
					n = {
						["gR"] = run_project,
						["gB"] = build_project,
						["gE"] = select_project_executable,
						["gC"] = clean_project,
						["gX"] = rebuild_project,
					},
				},
			},
		},
	})

	telescope.load_extension("project")

	vim.keymap.set("n", "<leader>pp", function()
		telescope.extensions.project.project()
	end, OPTS("Projects"))

	vim.keymap.set("n", "<leader>pr", open_project_run_picker, OPTS("Build and run C project"))
	vim.keymap.set("n", "<leader>pb", projects.build, OPTS("Build C project"))
	vim.keymap.set("n", "<leader>pc", projects.clean, OPTS("Clean C project"))
	vim.keymap.set("n", "<leader>pB", projects.rebuild, OPTS("Clean and rebuild C project"))
	vim.keymap.set("n", "<leader>pe", open_executable_picker, OPTS("Run project executable"))
	vim.keymap.set("n", "<leader>ps", projects.stop, OPTS("Stop project process"))
	vim.keymap.set("n", "<leader>pR", projects.rerun, OPTS("Rerun last executable"))
end

return M
