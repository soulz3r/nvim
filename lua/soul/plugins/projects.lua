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
	local projects = require("soul.core.projects")

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

	local function run_executable(prompt_bufnr)
		with_project(prompt_bufnr, projects.run_executable)
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
						["<C-e>"] = run_executable,
					},
					n = {
						["gR"] = run_project,
						["gB"] = build_project,
						["gE"] = run_executable,
					},
				},
			},
		},
	})

	telescope.load_extension("project")

	vim.keymap.set("n", "<leader>fp", function()
		telescope.extensions.project.project()
	end, OPTS("Projects"))

	vim.keymap.set("n", "<leader>rr", projects.run, OPTS("Build and run C project"))
	vim.keymap.set("n", "<leader>rb", projects.build, OPTS("Build C project"))
	vim.keymap.set("n", "<leader>re", projects.run_executable, OPTS("Run selected binary"))
end

return M
