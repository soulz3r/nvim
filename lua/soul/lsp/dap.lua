local M = {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"rcarriga/nvim-dap-ui",
		"soulz3r/yap.nvim",
	},
}

M.config = function()
	local dap = require("dap")
	local dapui = require("dapui")
	local dap_widgets = require("dap.ui.widgets")
	local fn = vim.fn
	local paths = require("soul.core.helpers.paths")
	local platform = require("soul.core.platform")
	local dap_args = require("soul.core.helpers.dap.args")
	local project_registry = require("yap.project_registry")

	-- =========================================================
	-- Project registry
	-- =========================================================

	local legacy_state_files = {
		fn.stdpath("config") .. "/lsp/dap-projects.json",
		fn.stdpath("state") .. "/soul/dap-projects.json",
	}

	local function normalize(path)
		if type(path) ~= "string" or path == "" then
			return nil
		end

		local normalized = fn.fnamemodify(fn.resolve(path), ":p"):gsub("\\", "/")

		if normalized == "/" or normalized:match("^%a:/$") then
			return normalized
		end

		return (normalized:gsub("/+$", ""))
	end

	local function project_key(path)
		local root = normalize(path)
		if not root then
			return nil
		end

		return platform.is_windows and root:lower() or root
	end

	local function is_executable(path)
		return type(path) == "string" and path ~= "" and fn.executable(path) == 1
	end

	local function is_within(path, root)
		path = project_key(path)
		root = project_key(root)

		if not path or not root then
			return false
		end

		if path == root then
			return true
		end

		local prefix = root:sub(-1) == "/" and root or (root .. "/")
		return path:sub(1, #prefix) == prefix
	end

	local dap_registry = require("soul.core.helpers.dap.registry")
	for _, legacy_path in ipairs(legacy_state_files) do
		dap_registry.migrate_file(legacy_path, project_registry, normalize)
	end

	local function copy_args(args)
		local result = {}

		if type(args) == "table" then
			for _, arg in ipairs(args) do
				if type(arg) == "string" then
					table.insert(result, arg)
				end
			end
		end

		return result
	end

	local function load_projects()
		local ok, entries = pcall(project_registry.list)
		if not ok or type(entries) ~= "table" then
			vim.notify("Could not read the YAP project registry: " .. tostring(entries), vim.log.levels.ERROR)
			return {}
		end

		local projects = {}
		for _, entry in ipairs(entries) do
			if type(entry) == "table" and type(entry.root) == "string" then
				local root = normalize(entry.root)
				local executable = entry.debug_executable or entry.last_executable
				local args = copy_args(entry.dap_args)
				local key = project_key(root)

				if key and (entry.dap_enabled or executable or type(entry.dap_args) == "table") then
					projects[key] = {
						root = root,
						executable = normalize(executable),
						args = args,
					}
				end
			end
		end

		return projects
	end

	local projects = load_projects()

	local function save_project(root, executable)
		root = normalize(root)
		local key = project_key(root)
		if not key then
			return nil
		end

		local fields = { dap_enabled = true }
		local normalized_executable

		if executable ~= nil then
			normalized_executable = normalize(executable)
			if not normalized_executable then
				return nil
			end

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

	-- =========================================================
	-- Resolve the project from the current buffer
	-- =========================================================

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

	-- An explicit project selection wins over the still-open buffer until
	-- the user moves to another buffer.
	local selected_project
	local project_selection_group = vim.api.nvim_create_augroup("SoulDapProjectSelection", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = project_selection_group,
		callback = function(args)
			if selected_project and args.buf ~= selected_project.buf then
				selected_project = nil
			end
		end,
	})

	local function current_file()
		local name = vim.api.nvim_buf_get_name(0)

		if name == "" then
			return nil
		end

		return normalize(name)
	end

	local function find_registered_ancestor(path)
		if not path then
			return nil
		end

		-- Refresh from the shared registry so projects added by YAP or another
		-- Neovim instance are visible without restarting this session.
		projects = load_projects()

		local best_root
		local best_length = -1

		for _, entry in pairs(projects) do
			if entry.root and is_within(path, entry.root) then
				if #entry.root > best_length then
					best_root = entry.root
					best_length = #entry.root
				end
			end
		end

		return best_root
	end

	local function resolve_project_root()
		if selected_project then
			if selected_project.buf == vim.api.nvim_get_current_buf() then
				return selected_project.root
			end

			selected_project = nil
		end

		local file = current_file()

		if file then
			local detected = vim.fs.root(0, root_markers)

			if detected then
				return normalize(detected)
			end

			local registered = find_registered_ancestor(file)

			if registered then
				return normalize(registered)
			end

			return normalize(fn.fnamemodify(file, ":h"))
		end

		local cwd = normalize(fn.getcwd())
		local detected = vim.fs.root(cwd, root_markers)

		if detected then
			return normalize(detected)
		end

		return find_registered_ancestor(cwd) or cwd
	end

	local function current_project()
		local root = resolve_project_root()

		if not root then
			return nil, nil
		end

		local key = project_key(root)
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

		if entry then
			return entry, root
		end

		return {
			root = root,
			executable = nil,
		}, root
	end

	-- =========================================================
	-- Find executables belonging to the current project
	-- =========================================================

	local function find_executables(root)
		local found = {}
		local seen = {}

		local function add(path)
			local executable = normalize(path)

			if not executable or not is_executable(executable) then
				return
			end

			local key = platform.is_windows and executable:lower() or executable

			if seen[key] then
				return
			end

			seen[key] = true
			table.insert(found, executable)
		end

		local ignored_directories = {
			[".git"] = true,
			["node_modules"] = true,
			[".venv"] = true,
			["venv"] = true,
		}

		local function scan(directory, depth, recursive)
			if fn.isdirectory(directory) ~= 1 then
				return
			end

			local ok, entries = pcall(vim.fs.dir, directory)
			if not ok then
				return
			end

			for name, kind in entries do
				local path = directory .. "/" .. name

				if kind == "file" then
					add(path)
				elseif recursive and kind == "directory" and depth < 3 and not ignored_directories[name] then
					scan(path, depth + 1, true)
				end
			end
		end

		-- Root-level files are cheap to inspect. Search output directories
		-- recursively, but keep traversal bounded and avoid dependency trees.
		scan(root, 0, false)
		for _, directory in ipairs({
			root .. "/bin",
			root .. "/build",
			root .. "/Debug",
			root .. "/Release",
		}) do
			scan(directory, 0, true)
		end

		table.sort(found, function(a, b)
			local function rank(path)
				local lower = path:lower()

				if lower:find("/bin/", 1, true) or lower:find("\\bin\\", 1, true) then
					return 1
				elseif lower:find("/build/", 1, true) or lower:find("\\build\\", 1, true) then
					return 2
				end

				return 3
			end

			local ra, rb = rank(a), rank(b)

			if ra ~= rb then
				return ra < rb
			end

			return a:lower() < b:lower()
		end)

		return found
	end

	-- =========================================================
	-- Select project and executable
	-- =========================================================

	local function select_project()
		local current_key = project_key(resolve_project_root())
		projects = load_projects()
		local entries = {}

		for key, entry in pairs(projects) do
			if type(entry) == "table" and entry.root then
				table.insert(entries, {
					key = key,
					root = entry.root,
					executable = entry.executable or "",
				})
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
			local marker = entry.key == current_key and " [active]" or ""
			table.insert(choices, entry.root .. marker)
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
					.. (entry.executable and entry.executable ~= "" and entry.executable or "Not configured"),
				vim.log.levels.INFO,
				{ title = "DAP" }
			)
		end)
	end

	local function select_executable()
		local entry, root = current_project()

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

			input = input:gsub('^"(.*)"$', "%1")
			input = input:gsub("^'(.*)'$", "%1")

			local executable = normalize(input)

			if not is_executable(executable) then
				vim.notify("Executable not found:\n" .. tostring(executable), vim.log.levels.ERROR)
				return
			end

			if not save_project(root, executable) then
				return
			end

			vim.notify("Executable saved for:\n" .. root .. "\n" .. executable, vim.log.levels.INFO, { title = "DAP" })
		end)
	end

	-- =========================================================
	-- Launch arguments
	-- =========================================================

	local format_args = dap_args.format

	local function parse_args(input)
		local args, parse_error = dap_args.parse(input, platform.is_windows)
		if not args then
			vim.notify(parse_error, vim.log.levels.ERROR)
		end
		return args
	end

	local function save_launch_args(root, args)
		root = normalize(root)
		local key = project_key(root)

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

	local function prompt_arguments(callback)
		local entry, root = current_project()

		if not entry or not root then
			vim.notify("Could not resolve a project for launch arguments.", vim.log.levels.ERROR)
			return
		end

		vim.ui.input({
			prompt = "Program arguments: ",
			default = format_args(entry.args or {}),
		}, function(input)
			if input == nil then
				return
			end

			local parsed = parse_args(input)

			if not parsed or not save_launch_args(root, parsed) then
				return
			end

			callback(parsed)
		end)
	end

	-- =========================================================
	-- LLDB adapter
	-- =========================================================

	dap.adapters.lldb = {
		type = "executable",
		command = paths.lldb_dap,
		name = "lldb",
	}

	local function make_launch_config(root, executable, args, name)
		return {
			name = name or "Launch executable",
			type = "lldb",
			request = "launch",
			program = executable,
			cwd = root,
			args = args or {},
			stopOnEntry = false,
			runInTerminal = false,
		}
	end

	local function configured_program()
		local entry, root = current_project()

		if not entry or not root then
			return nil
		end

		if is_executable(entry.executable) then
			return entry.executable
		end

		local candidates = find_executables(root)

		if #candidates == 1 then
			save_project(root, candidates[1])
			return candidates[1]
		end

		vim.notify(
			#candidates > 1 and "Multiple executables found. Use <leader>dc to choose one."
				or "No executable found for this project. Use <leader>de to configure one.",
			vim.log.levels.WARN
		)

		return nil
	end

	local function launch_config(args)
		return {
			name = "Launch current project",
			type = "lldb",
			request = "launch",
			program = configured_program,
			cwd = function()
				local _, root = current_project()
				return root or fn.getcwd()
			end,
			args = args or {},
			stopOnEntry = false,
			runInTerminal = false,
		}
	end

	dap.configurations.c = {
		launch_config({}),
		launch_config({ "tree" }),
	}

	dap.configurations.cpp = dap.configurations.c
	dap.configurations.rust = dap.configurations.c

	dap.defaults.fallback.switchbuf = "useopen"

	-- =========================================================
	-- DAP UI
	-- =========================================================

	dapui.setup({
		icons = {
			expanded = "▾",
			collapsed = "▸",
			current_frame = "▸",
		},
		mappings = {
			expand = { "<CR>", "<2-LeftMouse>" },
			open = "o",
			remove = "d",
			edit = "e",
			toggle = "t",
			expand_all = "E",
		},
		controls = {
			enabled = true,
			element = "repl",
			icons = {
				pause = "⏸",
				play = "▶",
				step_into = "↴",
				step_over = "↷",
				step_out = "↰",
				step_back = "←",
				run_last = "↻",
				terminate = "■",
				disconnect = "⏏",
			},
		},
		floating = {
			border = "rounded",
			mappings = {
				close = { "q", "<Esc>" },
			},
		},
		windows = {
			indent = 1,
		},
	})

	-- =========================================================
	-- Restore source window after debugging
	-- =========================================================

	local source_context

	local function remember_source()
		local win = vim.api.nvim_get_current_win()

		if not vim.api.nvim_win_is_valid(win) then
			return
		end

		local buf = vim.api.nvim_win_get_buf(win)

		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		source_context = {
			win = win,
			buf = buf,
			cursor = vim.api.nvim_win_get_cursor(win),
		}
	end

	local function restore_source()
		local context = source_context

		if not context then
			return
		end

		vim.schedule(function()
			if not vim.api.nvim_win_is_valid(context.win) then
				source_context = nil
				return
			end

			vim.api.nvim_set_current_win(context.win)

			if vim.api.nvim_buf_is_valid(context.buf) then
				vim.api.nvim_win_set_buf(context.win, context.buf)

				local count = vim.api.nvim_buf_line_count(context.buf)
				local line = math.max(1, math.min(context.cursor[1], count))

				pcall(vim.api.nvim_win_set_cursor, context.win, {
					line,
					context.cursor[2],
				})
			end

			source_context = nil
		end)
	end

	dap.listeners.before.event_initialized["soul_dap_source"] = function()
		remember_source()
		dapui.open()
	end

	dap.listeners.after.event_exited["soul_dap_source"] = restore_source
	dap.listeners.after.event_terminated["soul_dap_source"] = restore_source

	-- =========================================================
	-- Start/continue: resolve the current project's executable
	-- =========================================================

	local function start_or_continue()
		if dap.session() then
			dap.continue()
			return
		end

		local entry, root = current_project()

		if not entry or not root then
			vim.notify("Could not resolve a project for the current file.", vim.log.levels.ERROR)
			return
		end

		local function launch(executable)
			if not is_executable(executable) then
				vim.notify("Executable not found:\n" .. tostring(executable), vim.log.levels.ERROR)
				return
			end

			save_project(root, executable)

			prompt_arguments(function(args)
				local config = make_launch_config(root, executable, args, "Launch " .. fn.fnamemodify(executable, ":t"))

				dap.run(config)
			end)
		end

		if is_executable(entry.executable) then
			launch(entry.executable)
			return
		end

		local candidates = find_executables(root)

		if #candidates == 1 then
			launch(candidates[1])
			return
		end

		if #candidates > 1 then
			vim.ui.select(candidates, {
				prompt = "Choose executable for " .. root,
				format_item = function(path)
					return fn.fnamemodify(path, ":~:.")
				end,
			}, function(choice)
				if choice then
					launch(choice)
				end
			end)

			return
		end

		vim.notify(
			"No executable found for this project:\n"
				.. root
				.. "\nSearched: bin/, build/, build/Debug/, build/Release/, "
				.. "Debug/, Release/, and the project root.\n"
				.. "Use <leader>de to set the executable manually.",
			vim.log.levels.WARN
		)
	end

	-- =========================================================
	-- Keymap helpers
	-- =========================================================

	local function map(mode, lhs, callback, desc)
		vim.keymap.set(mode, lhs, callback, {
			noremap = true,
			silent = true,
			desc = desc,
		})
	end

	local function call_dap(name, ...)
		local callback = dap[name]

		if type(callback) ~= "function" then
			vim.notify("nvim-dap does not provide dap." .. name, vim.log.levels.ERROR)
			return
		end

		return callback(...)
	end

	-- =========================================================
	-- REPL: search existing REPL lines with Telescope if available
	-- =========================================================

	local function get_repl_buffer()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "dap-repl" then
				return buf
			end
		end

		return nil
	end

	local function search_repl()
		local repl_buf = get_repl_buffer()

		if not repl_buf then
			dap.repl.open()
			repl_buf = get_repl_buffer()
		end

		if not repl_buf then
			vim.notify("Could not find the DAP REPL buffer.", vim.log.levels.WARN)
			return
		end

		local lines = vim.api.nvim_buf_get_lines(repl_buf, 0, -1, false)

		if #lines == 0 then
			vim.notify("The DAP REPL is empty.", vim.log.levels.INFO)
			return
		end

		local entries = {}

		for line_number, line in ipairs(lines) do
			table.insert(entries, { line = line, lnum = line_number })
		end

		local function jump_to_line(line_number)
			if not vim.api.nvim_buf_is_valid(repl_buf) then
				return
			end

			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == repl_buf then
					vim.api.nvim_set_current_win(win)
					vim.api.nvim_win_set_cursor(win, { line_number, 0 })
					return
				end
			end

			vim.cmd("sbuffer " .. repl_buf)
			vim.api.nvim_win_set_cursor(0, { line_number, 0 })
		end

		local ok, pickers = pcall(require, "telescope.pickers")

		if not ok then
			vim.ui.select(entries, {
				prompt = "Select DAP REPL line",
				format_item = function(entry)
					return string.format("%4d  %s", entry.lnum, entry.line)
				end,
			}, function(choice)
				if choice then
					jump_to_line(choice.lnum)
				end
			end)
			return
		end

		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		pickers
			.new({}, {
				prompt_title = "DAP REPL",
				finder = finders.new_table({
					results = entries,
					entry_maker = function(entry)
						return {
							value = entry,
							display = string.format("%4d  %s", entry.lnum, entry.line),
							ordinal = entry.line,
							lnum = entry.lnum,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr)
					actions.select_default:replace(function()
						local selection = action_state.get_selected_entry()
						actions.close(prompt_bufnr)

						if selection then
							jump_to_line(selection.value.lnum)
						end
					end)

					return true
				end,
			})
			:find()
	end

	local function open_or_focus_repl()
		local repl_buf = get_repl_buffer()

		if repl_buf then
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == repl_buf then
					vim.api.nvim_set_current_win(win)
					return
				end
			end
		end

		dap.repl.open()
	end

	-- Session / project
	map("n", "<leader>dc", start_or_continue, "DAP: Start / continue with arguments")

	map("n", "<leader>dr", function()
		if not dap.session() then
			vim.notify("No active debug session to restart.", vim.log.levels.WARN)
			return
		end

		call_dap("restart")
	end, "DAP: Restart session")

	map("n", "<leader>dk", function()
		if not dap.session() then
			vim.notify("No active debug session to kill.", vim.log.levels.WARN)
			return
		end

		call_dap("terminate")
	end, "DAP: Kill session")

	map("n", "<leader>dl", function()
		call_dap("run_last")
	end, "DAP: Run last configuration")

	map("n", "<leader>dp", select_project, "DAP: Select saved project")
	map("n", "<leader>de", select_executable, "DAP: Set executable")

	-- Breakpoints
	map("n", "<leader>dx", function()
		call_dap("toggle_breakpoint")
	end, "DAP: Toggle breakpoint")

	map("n", "<leader>dB", function()
		vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
			if condition ~= nil then
				call_dap("set_breakpoint", condition ~= "" and condition or nil)
			end
		end)
	end, "DAP: Conditional breakpoint")

	map("n", "<leader>dL", function()
		vim.ui.input({ prompt = "Log message: " }, function(message)
			if message and message ~= "" then
				call_dap("set_breakpoint", nil, nil, message)
			end
		end)
	end, "DAP: Logpoint")

	map("n", "<leader>dX", function()
		call_dap("clear_breakpoints")
	end, "DAP: Clear all breakpoints")

	map("n", "<leader>dK", function()
		call_dap("list_breakpoints")
	end, "DAP: List breakpoints")

	-- Stepping
	map("n", "<leader>ds", function()
		call_dap("step_over")
	end, "DAP: Step over")

	map("n", "<leader>di", function()
		call_dap("step_into")
	end, "DAP: Step into")

	map("n", "<leader>do", function()
		call_dap("step_out")
	end, "DAP: Step out")

	map("n", "<leader>dS", function()
		call_dap("step_back")
	end, "DAP: Step back")

	map("n", "<leader>dP", function()
		call_dap("pause")
	end, "DAP: Pause")

	map("n", "<leader>dG", function()
		call_dap("run_to_cursor")
	end, "DAP: Run to cursor")

	map("n", "<leader>dJ", function()
		call_dap("goto_")
	end, "DAP: Go to current line")

	map("n", "<leader>dU", function()
		call_dap("up")
	end, "DAP: Older stack frame")

	map("n", "<leader>dD", function()
		call_dap("down")
	end, "DAP: Newer stack frame")

	map("n", "<leader>dF", function()
		call_dap("focus_frame")
	end, "DAP: Focus frame")

	-- Evaluation / REPL
	map({ "n", "v" }, "<leader>dh", function()
		dap_widgets.hover()
	end, "DAP: Evaluate expression")

	map("n", "<leader>dR", open_or_focus_repl, "DAP: Open or focus REPL")
	map("n", "<leader>d/", search_repl, "DAP: Search REPL")

	map("n", "<leader>dw", function()
		local watches = dapui.elements.watches

		if watches and type(watches.add) == "function" then
			watches.add()
		else
			vim.notify("Watch expressions are unavailable.", vim.log.levels.WARN)
		end
	end, "DAP: Add watch")

	-- UI
	map("n", "<leader>du", function()
		dapui.toggle()
	end, "DAP UI: Toggle")

	map("n", "<leader>dt", function()
		vim.ui.select({
			"scopes",
			"stacks",
			"watches",
			"breakpoints",
			"repl",
			"console",
		}, {
			prompt = "Open floating DAP element",
		}, function(element)
			if element then
				dapui.float_element(element, {})
			end
		end)
	end, "DAP UI: Float element")

	-- Diagnostics
	map("n", "<leader>d?", function()
		call_dap("show_log")
	end, "DAP: Show log")

	-- Function keys: match the standard debugging convention
	map("n", "<F5>", start_or_continue, "DAP: Start / continue with arguments")

	map("n", "<F9>", function()
		call_dap("toggle_breakpoint")
	end, "DAP: Toggle breakpoint")

	map("n", "<F10>", function()
		call_dap("step_over")
	end, "DAP: Step over")

	map("n", "<F11>", function()
		call_dap("step_into")
	end, "DAP: Step into")

	map("n", "<F12>", function()
		call_dap("step_out")
	end, "DAP: Step out")
end

return M
