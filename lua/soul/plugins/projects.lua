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
	local project_runs = require("soul.core.project_runs")

	local function prompt_arguments(root, executable, should_run)
		local saved = project_runs.get(root, executable)

		vim.ui.input({
			title = " " .. vim.fn.fnamemodify(executable, ":t") .. " ",
			prompt = "Arguments: ",
			default = saved,
		}, function(input)
			if input == nil then
				return
			end

			local args, err = projects.parse_args(input)
			if not args then
				vim.notify(err, vim.log.levels.ERROR)
				return
			end

			if not project_runs.set(root, executable, input) then
				return
			end

			if should_run then
				projects.run_binary(executable, root, args)
			end
		end)
	end

	local function run_saved(root, executable)
		local saved = project_runs.get(root, executable)
		local args, err = projects.parse_args(saved)

		if not args then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end

		projects.run_binary(executable, root, args)
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
					local saved = project_runs.get(root, file)
					local name = vim.fn.fnamemodify(file, ":t")
					local relative = vim.fs.relpath(root, file) or file

					return {
						value = file,
						ordinal = name .. " " .. relative .. " " .. saved,
						display = name .. (saved ~= "" and "  [" .. saved .. "]" or ""),
						filename = file,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = false,
			attach_mappings = function(prompt_bufnr, map)
				local function selected(run_now)
					local entry = action_state.get_selected_entry()
					if not entry then
						return
					end

					actions.close(prompt_bufnr)
					vim.schedule(function()
						if run_now == "saved" then
							run_saved(root, entry.value)
						else
							prompt_arguments(root, entry.value, run_now)
						end
					end)
				end

				actions.select_default:replace(function()
					selected(true)
				end)

				map("i", "<C-r>", function()
					selected("saved")
				end)
				map("n", "<C-r>", function()
					selected("saved")
				end)

				map("i", "<C-e>", function()
					selected(false)
				end)
				map("n", "<C-e>", function()
					selected(false)
				end)

				return true
			end,
		}):find()
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
		with_project(prompt_bufnr, projects.run)
	end

	local function build_project(prompt_bufnr)
		with_project(prompt_bufnr, projects.build)
	end

	local function select_project_executable(prompt_bufnr)
		with_project(prompt_bufnr, open_executable_picker)
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
					},
				},
			},
		},
	})

	telescope.load_extension("project")

	vim.keymap.set("n", "<leader>pp", function()
		telescope.extensions.project.project()
	end, OPTS("Projects"))

	vim.keymap.set("n", "<leader>pr", projects.run, OPTS("Build and run C project"))
	vim.keymap.set("n", "<leader>pb", projects.build, OPTS("Build C project"))
	vim.keymap.set("n", "<leader>pe", open_executable_picker, OPTS("Run project executable"))
end

return M
