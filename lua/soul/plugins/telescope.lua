local OPTS = require("soul.core.helpers.keymaps").opts

local M = {
	"nvim-telescope/telescope.nvim",

	dependencies = {
		"nvim-lua/plenary.nvim",

		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = function(plugin)
				local fn = vim.fn
				local paths = require("soul.core.helpers.paths")
				local windows = require("soul.core.platform").is_windows
				local build_dir = plugin.dir .. "/build"
				local library = build_dir .. "/" .. (windows and "libfzf.dll" or "libfzf.so")

				local function clean_build()
					local result = fn.delete(build_dir, "rf")
					if result ~= 0 and vim.uv.fs_stat(build_dir) then
						return false,
							"Could not remove the previous native build directory. Restart Neovim before rebuilding."
					end
					return true
				end

				local function run(command)
					local ok, process = pcall(vim.system, command, {
						cwd = plugin.dir,
						text = true,
					})

					if not ok then
						return false, tostring(process)
					end

					local result, wait_error = require("soul.core.helpers.process").wait(process, 120000)
					if not result then
						return false, wait_error or "Build timed out after 120 seconds."
					end

					return result.code == 0,
						table.concat({
							result.stdout or "",
							result.stderr or "",
						}, "\n")
				end

				local errors = {}
				local clean_ok, clean_error = clean_build()
				if not clean_ok then
					error(clean_error)
				end

				-- Prefer CMake on Windows when available. Its MSVC build uses the
				-- static CRT, avoiding a separate Visual C++ runtime dependency.
				if windows then
					local cmake = fn.exepath("cmake")
					if cmake ~= "" then
						local configure_ok, configure_output = run({
							cmake,
							"-S",
							".",
							"-B",
							"build",
							"-DCMAKE_BUILD_TYPE=Release",
							"-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
							"-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded",
						})

						if configure_ok then
							local build_ok, build_output = run({
								cmake,
								"--build",
								"build",
								"--config",
								"Release",
							})

							if build_ok then
								local install_ok, install_output = run({
									cmake,
									"--install",
									"build",
									"--config",
									"Release",
									"--prefix",
									"build",
								})

								if install_ok and vim.uv.fs_stat(library) then
									return
								end
								table.insert(errors, "CMake install failed:\n" .. install_output)
							else
								table.insert(errors, "CMake build failed:\n" .. build_output)
							end
						else
							table.insert(errors, "CMake configure failed:\n" .. configure_output)
						end

						local cleaned, cleanup_error = clean_build()
						if not cleaned then
							table.insert(errors, cleanup_error)
						end
					end
				end

				local make = fn.exepath("make")
				if windows and make == "" then
					make = fn.exepath("mingw32-make")
				end

				if make ~= "" then
					local command = { make, "-C", plugin.dir }
					if windows then
						local compiler = paths.clang or fn.exepath("clang")
						if compiler and compiler ~= "" then
							command[#command + 1] = 'CC="' .. compiler .. '"'
						end
					end

					local make_ok, make_output = run(command)
					if make_ok and vim.uv.fs_stat(library) then
						return
					end
					table.insert(errors, "Make build failed:\n" .. make_output)
				else
					table.insert(errors, "GNU Make was not found.")
				end

				-- Last-resort Windows path for LLVM-only setups without Make/CMake.
				if windows then
					local cleaned, cleanup_error = clean_build()
					if not cleaned then
						table.insert(errors, cleanup_error)
					else
						fn.mkdir(build_dir, "p")

						local clang_cl = fn.exepath("clang-cl")
						if clang_cl ~= "" then
							local ok, output = run({
								clang_cl,
								"/nologo",
								"/O2",
								"/W4",
								"/MT",
								"/LD",
								"/std:c11",
								"src/fzf.c",
								"/Fe:build/libfzf.dll",
							})

							if ok and vim.uv.fs_stat(library) then
								return
							end
							table.insert(errors, "clang-cl build failed:\n" .. output)
						end

						local clang = paths.clang or fn.exepath("clang")
						if clang and clang ~= "" then
							local ok, output = run({
								clang,
								"-O3",
								"-Wall",
								"-fpic",
								"-std=gnu99",
								"-shared",
								"src/fzf.c",
								"-o",
								"build/libfzf.dll",
							})

							if ok and vim.uv.fs_stat(library) then
								return
							end
							table.insert(errors, "Clang build failed:\n" .. output)
						end
					end
				end

				error(
					"Could not build telescope-fzf-native.nvim.\n"
						.. table.concat(errors, "\n\n")
						.. "\nInstall a C compiler and Make, or CMake with Visual Studio Build Tools on Windows. "
						.. "Then run :Lazy build telescope-fzf-native.nvim."
				)
			end,
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

	local keymap = vim.keymap.set

	keymap("n", "<leader>fb", "<cmd>Telescope buffers previewer=false<CR>", OPTS("Buffers"))

	keymap("n", "<leader>fC", "<cmd>Telescope colorscheme<CR>", OPTS("Colorscheme"))

	keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>", OPTS("Find Files"))

	keymap("n", "<leader>ft", "<cmd>Telescope live_grep<CR>", OPTS("Live Grep"))

	keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", OPTS("Help"))

	keymap("n", "<leader>fr", "<cmd>Telescope resume<CR>", OPTS("Resume"))

	keymap("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", OPTS("Recent Files"))

	keymap("n", "<leader>flr", "<cmd>Telescope lsp_references<CR>", OPTS("LSP References"))

	keymap("n", "<leader>fld", "<cmd>Telescope lsp_definitions<CR>", OPTS("LSP Definitions"))

	keymap("n", "<leader>flD", "<cmd>Telescope lsp_declarations<CR>", OPTS("LSP Declarations"))

	keymap("n", "<leader>fli", "<cmd>Telescope lsp_implementations<CR>", OPTS("LSP Implementations"))

	keymap("n", "<leader>flt", "<cmd>Telescope lsp_type_definitions<CR>", OPTS("LSP Type Definitions"))

	keymap("n", "<leader>fgb", "<cmd>Telescope git_branches<CR>", OPTS("Git Branches"))

	keymap("n", "<leader>fgc", "<cmd>Telescope git_commits<CR>", OPTS("Git Commits"))

	keymap("n", "<leader>fgs", "<cmd>Telescope git_status<CR>", OPTS("Git Status"))

	keymap("n", "<leader>fgS", "<cmd>Telescope git_stash<CR>", OPTS("Git Stash"))

	keymap("n", "<leader>fgf", "<cmd>Telescope git_files<CR>", OPTS("Git Files"))

	keymap("n", "<leader>fgB", "<cmd>Telescope git_bcommits<CR>", OPTS("Git Buffer Commits"))

	keymap("n", "<leader>fs", "<cmd>Telescope treesitter<CR>", OPTS("Treesitter Symbols"))

	keymap("n", "<leader>fx", "<cmd>Telescope diagnostics<CR>", OPTS("Diagnostics"))

	keymap("n", "<leader>fch", "<cmd>Telescope command_history<CR>", OPTS("Command History"))

	keymap("n", "<leader>fcc", "<cmd>Telescope commands<CR>", OPTS("Commands"))

	keymap("n", "<leader>fy", "<cmd>Telescope registers<CR>", OPTS("Registers"))

	keymap("n", "<leader>fm", "<cmd>Telescope marks<CR>", OPTS("Marks"))
end

return M
