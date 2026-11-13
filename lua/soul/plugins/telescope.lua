local M = {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",

	keys = {
		{ "<leader>fb", "<cmd>Telescope buffers previewer=false<CR>", desc = "Buffers" },
		{ "<leader>fC", "<cmd>Telescope colorscheme<CR>", desc = "Colorscheme" },
		{ "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
		{ "<leader>ft", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
		{ "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
		{ "<leader>fr", "<cmd>Telescope resume<CR>", desc = "Resume" },
		{ "<leader>fo", "<cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
		{ "<leader>flr", "<cmd>Telescope lsp_references<CR>", desc = "LSP References" },
		{ "<leader>fld", "<cmd>Telescope lsp_definitions<CR>", desc = "LSP Definitions" },
		{ "<leader>flD", "<cmd>Telescope lsp_declarations<CR>", desc = "LSP Declarations" },
		{ "<leader>fli", "<cmd>Telescope lsp_implementations<CR>", desc = "LSP Implementations" },
		{ "<leader>flt", "<cmd>Telescope lsp_type_definitions<CR>", desc = "LSP Type Definitions" },
		{ "<leader>fgb", "<cmd>Telescope git_branches<CR>", desc = "Git Branches" },
		{ "<leader>fgc", "<cmd>Telescope git_commits<CR>", desc = "Git Commits" },
		{ "<leader>fgs", "<cmd>Telescope git_status<CR>", desc = "Git Status" },
		{ "<leader>fgS", "<cmd>Telescope git_stash<CR>", desc = "Git Stash" },
		{ "<leader>fgf", "<cmd>Telescope git_files<CR>", desc = "Git Files" },
		{ "<leader>fgB", "<cmd>Telescope git_bcommits<CR>", desc = "Git Buffer Commits" },
		{ "<leader>fs", "<cmd>Telescope treesitter<CR>", desc = "Treesitter Symbols" },
		{ "<leader>fx", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
		{ "<leader>fch", "<cmd>Telescope command_history<CR>", desc = "Command History" },
		{ "<leader>fcc", "<cmd>Telescope commands<CR>", desc = "Commands" },
		{ "<leader>fy", "<cmd>Telescope registers<CR>", desc = "Registers" },
		{ "<leader>fm", "<cmd>Telescope marks<CR>", desc = "Marks" },
	},

	dependencies = {
		"nvim-lua/plenary.nvim",

		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = require("soul.core.helpers.fzf_native").build,
		},

		"nvim-telescope/telescope-ui-select.nvim",
	},
}

function M.config()
	local telescope = require("telescope")
	local actions = require("telescope.actions")
	local actions_layout = require("telescope.actions.layout")

	local ok, icons = pcall(require, "soul.core.helpers.icons")

	if not ok then
		icons = {
			ui = {
				Telescope = "",
				Forward = "",
			},
		}
	end

	telescope.setup({
		defaults = {
			history = {
				path = vim.fn.stdpath("data") .. "/telescope_history",
				limit = 100,
			},

			winblend = 0,
			borderchars = require("soul.core.helpers.ui.floats").telescope_borderchars,

			prompt_prefix = icons.ui.Telescope .. " ",
			selection_caret = icons.ui.Forward .. " ",
			entry_prefix = " ",

			initial_mode = "insert",
			selection_strategy = "reset",
			sorting_strategy = "descending",
			scroll_strategy = "cycle",

			path_display = { "tail" },
			color_devicons = true,

			vimgrep_arguments = {
				"rg",
				"--color=never",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
				"--smart-case",
				"--hidden",
				"--glob=!.git/",
			},

			mappings = {
				i = {
					["<C-n>"] = actions.move_selection_next,
					["<C-p>"] = actions.move_selection_previous,

					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,

					["<C-a>"] = actions.select_all,
					["<C-x>"] = actions.drop_all,

					["<C-Up>"] = actions.cycle_history_prev,
					["<C-Down>"] = actions.cycle_history_next,

					["<C-space>"] = actions_layout.toggle_preview,
					["<C-f>"] = actions.to_fuzzy_refine,
				},

				n = {
					["<C-space>"] = actions_layout.toggle_preview,
					["<C-n>"] = actions.move_selection_next,
					["<C-p>"] = actions.move_selection_previous,
					["<C-f>"] = actions.to_fuzzy_refine,
					["<C-a>"] = actions.select_all,
					["<C-x>"] = actions.drop_all,

					["<esc>"] = actions.close,
					["q"] = actions.close,

					["j"] = actions.move_selection_next,
					["k"] = actions.move_selection_previous,

					["gg"] = actions.move_to_top,
					["G"] = actions.move_to_bottom,
				},
			},
		},

		pickers = {
			find_files = {
				theme = "dropdown",
				previewer = true,
				hidden = true,
				no_ignore = false,
				follow = true,
			},

			live_grep = {
				theme = "dropdown",
			},

			grep_string = {
				theme = "dropdown",
			},

			buffers = {
				theme = "dropdown",
				previewer = false,
				initial_mode = "insert",
				path_display = { "tail" },

				mappings = {
					i = {
						["<C-n>"] = actions.move_selection_next,
						["<C-p>"] = actions.move_selection_previous,
						["<C-d>"] = actions.delete_buffer,
					},

					n = {
						["dd"] = actions.delete_buffer,
					},
				},
			},

			oldfiles = {
				theme = "dropdown",
				previewer = false,
			},

			marks = {
				theme = "dropdown",
				previewer = true,

				mappings = {
					n = {
						["dd"] = actions.delete_mark,
					},
				},
			},

			registers = {
				theme = "dropdown",
				previewer = true,

				mappings = {
					n = {
						["dd"] = function(prompt_bufnr)
							local action_state = require("telescope.actions.state")
							local picker = action_state.get_current_picker(prompt_bufnr)
							local selection = action_state.get_selected_entry()

							if not selection then
								return
							end

							picker:delete_selection(function()
								vim.fn.setreg(selection.value, "")
								return true
							end)
						end,
					},
				},
			},

			help_tags = {
				theme = "dropdown",
			},

			git_branches = {
				theme = "dropdown",
			},

			colorscheme = {
				theme = "dropdown",
				enable_preview = true,
			},

			lsp_references = {
				theme = "dropdown",
				initial_mode = "normal",
			},

			lsp_definitions = {
				theme = "dropdown",
				initial_mode = "normal",
			},

			lsp_declarations = {
				theme = "dropdown",
				initial_mode = "normal",
			},

			lsp_implementations = {
				theme = "dropdown",
				initial_mode = "normal",
			},
		},

		extensions = {
			fzf = {
				fuzzy = true,
				override_generic_sorter = true,
				override_file_sorter = true,
				case_mode = "smart_case",
			},

			["ui-select"] = require("telescope.themes").get_dropdown({}),
		},
	})

	local function load_extension(name)
		local ok, err = pcall(telescope.load_extension, name)

		if not ok then
			local message = ("Telescope extension '%s' failed to load: %s"):format(name, tostring(err))

			if name == "fzf" then
				message = message .. "\nRebuild the native library with :Lazy build telescope-fzf-native.nvim."
			end

			vim.notify(message, vim.log.levels.WARN, { title = "Telescope" })
		end
	end

	load_extension("fzf")
	load_extension("ui-select")

end

return M
