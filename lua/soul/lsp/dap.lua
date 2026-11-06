local M = {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"rcarriga/nvim-dap-ui",
	},
}

M.config = function()
	local dap = require("dap")
	local dapui = require("dapui")
	local dap_widgets = require("dap.ui.widgets")
	local fn = vim.fn

	-- =========================================================
	-- Project registry
	-- =========================================================

	local state_file = fn.stdpath("config") .. "/lsp/dap-projects.json"
	fn.mkdir(fn.fnamemodify(state_file, ":h"), "p")

	local function normalize(path)
		if type(path) ~= "string" or path == "" then
			return nil
		end

		return fn.fnamemodify(fn.resolve(path), ":p"):gsub("[/\\]+$", "")
	end

	local function project_key(path)
		local root = normalize(path)
		return root and root:lower() or nil
	end

	local function read_json()
		local file = io.open(state_file, "r")

		if not file then
			return {}
		end

		local content = file:read("*a")
		file:close()

		local ok, data = pcall(fn.json_decode, content)

		if not ok or type(data) ~= "table" then
			vim.notify(
				"Could not parse DAP project registry:\n" .. state_file,
				vim.log.levels.ERROR
			)
			return {}
		end

		return data
	end

	local function write_json(data)
		local file = io.open(state_file, "w")

		if not file then
			vim.notify(
				"Could not save DAP project registry:\n" .. state_file,
				vim.log.levels.ERROR
			)
			return false
		end

		file:write(fn.json_encode(data))
		file:close()
		return true
	end

	-- Preserve the original flat registry format while also reading
	-- the wrapper format used by the earlier version.
	local raw_data = read_json()
	local projects = {}
	local active_root

	if type(raw_data.projects) == "table" then
		active_root = raw_data.active_root

		for key, entry in pairs(raw_data.projects) do
			if type(entry) == "table" then
				local root = normalize(entry.root or key)
				local k = project_key(root)

				if k then
					projects[k] = {
						root = root,
						executable = entry.executable,
					}
				end
			end
		end
	else
		for key, entry in pairs(raw_data) do
			if type(entry) == "table" then
				local root = normalize(entry.root or key)
				local k = project_key(root)

				if k then
					projects[k] = {
						root = root,
						executable = entry.executable,
					}
				end
			end
		end
	end

	local function save_projects()
		return write_json(projects)
	end

	local function file_exists(path)
		return type(path) == "string"
			and path ~= ""
			and fn.filereadable(path) == 1
	end

	local function is_within(path, root)
		path = normalize(path)
		root = normalize(root)

		if not path or not root then
			return false
		end

		path = path:lower()
		root = root:lower()

		return path == root
			or path:sub(1, #root + 1) == root .. "/"
			or path:sub(1, #root + 1) == root .. "\\"
	end

	local function save_project(root, executable)
		root = normalize(root)
		local key = project_key(root)

		if not key then
			return nil
		end

		local entry = projects[key] or {
			root = root,
		}

		entry.root = root

		if executable ~= nil then
			entry.executable = normalize(executable)
		end

		projects[key] = entry
		active_root = key
		save_projects()

		return entry
	end

	-- =========================================================
	-- Resolve the project from the current buffer
	-- =========================================================

	local root_markers = {
		".git",
		"CMakeLists.txt",
		"Makefile",
		"makefile",
		"build.ninja",
		"compile_commands.json",
		"meson.build",
		"Cargo.toml",
	}

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

		if entry then
			active_root = key
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

			if not executable or not file_exists(executable) then
				return
			end

			local key = executable:lower()

			if seen[key] then
				return
			end

			seen[key] = true
			table.insert(found, executable)
		end

		local directories = {
			root .. "/bin",
			root .. "/build",
			root .. "/build/Debug",
			root .. "/build/Release",
			root .. "/Debug",
			root .. "/Release",
			root,
		}

		for _, directory in ipairs(directories) do
			if fn.isdirectory(directory) == 1 then
				for name, kind in vim.fs.dir(directory) do
					if kind == "file" and name:lower():match("%.exe$") then
						add(directory .. "/" .. name)
					end
				end
			end
		end

		table.sort(found, function(a, b)
			local function rank(path)
				local lower = path:lower()

				if lower:find("/bin/", 1, true)
					or lower:find("\\bin\\", 1, true)
				then
					return 1
				elseif lower:find("/build/", 1, true)
					or lower:find("\\build\\", 1, true)
				then
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
			vim.notify(
				"No saved projects in:\n" .. state_file,
				vim.log.levels.WARN
			)
			return
		end

		local choices = {}

		for _, entry in ipairs(entries) do
			local marker = entry.key == active_root and " [active]" or ""
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
				vim.notify(
					"Project directory does not exist:\n" .. entry.root,
					vim.log.levels.ERROR
				)
				return
			end

			active_root = entry.key
			vim.cmd.cd(entry.root)

			vim.notify(
				"Selected project:\n" .. entry.root
					.. "\nExecutable: "
					.. (entry.executable ~= "" and entry.executable or "Not configured"),
				vim.log.levels.INFO
			)
		end)
	end

	local function select_executable()
		local entry, root = current_project()

		if not entry or not root then
			vim.notify(
				"Could not resolve the current project's root.",
				vim.log.levels.ERROR
			)
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

			if not file_exists(executable) then
				vim.notify(
					"Executable not found:\n" .. tostring(executable),
					vim.log.levels.ERROR
				)
				return
			end

			save_project(root, executable)

			vim.notify(
				"Executable saved for:\n" .. root .. "\n" .. executable,
				vim.log.levels.INFO
			)
		end)
	end

	-- =========================================================
	-- Launch arguments
	-- =========================================================

	local launch_args = {}

	local function parse_args(input)
		local args = {}
		local current = {}
		local quote = nil
		local escaped = false

		for i = 1, #input do
			local char = input:sub(i, i)

			if escaped then
				table.insert(current, char)
				escaped = false
			elseif char == "\\" and quote ~= "'" then
				escaped = true
			elseif quote then
				if char == quote then
					quote = nil
				else
					table.insert(current, char)
				end
			elseif char == '"' or char == "'" then
				quote = char
			elseif char:match("%s") then
				if #current > 0 then
					table.insert(args, table.concat(current))
					current = {}
				end
			else
				table.insert(current, char)
			end
		end

		if escaped then
			table.insert(current, "\\")
		end

		if quote then
			vim.notify(
				"Unclosed quote in program arguments.",
				vim.log.levels.ERROR
			)
			return nil
		end

		if #current > 0 then
			table.insert(args, table.concat(current))
		end

		return args
	end

	local function prompt_arguments(callback)
		vim.ui.input({
			prompt = "Program arguments: ",
			default = table.concat(launch_args, " "),
		}, function(input)
			if input == nil then
				return
			end

			local parsed = parse_args(input)

			if not parsed then
				return
			end

			launch_args = parsed
			callback(parsed)
		end)
	end

	-- =========================================================
	-- LLDB adapter
	-- =========================================================

	dap.adapters.lldb = {
		type = "executable",
		command = "C:/Program Files/LLVM/bin/lldb-dap.exe",
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

		if file_exists(entry.executable) then
			return entry.executable
		end

		local candidates = find_executables(root)

		if #candidates == 1 then
			save_project(root, candidates[1])
			return candidates[1]
		end

		vim.notify(
			#candidates > 1
				and "Multiple executables found. Use <leader>dc to choose one."
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
			vim.notify(
				"Could not resolve a project for the current file.",
				vim.log.levels.ERROR
			)
			return
		end

		local function launch(executable)
			if not file_exists(executable) then
				vim.notify(
					"Executable not found:\n" .. tostring(executable),
					vim.log.levels.ERROR
				)
				return
			end

			save_project(root, executable)

			prompt_arguments(function(args)
				local config = make_launch_config(
					root,
					executable,
					args,
					"Launch " .. fn.fnamemodify(executable, ":t")
				)

				dap.run(config)
			end)
		end

		if file_exists(entry.executable) then
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
			vim.notify(
				"nvim-dap does not provide dap." .. name,
				vim.log.levels.ERROR
			)
			return
		end

		return callback(...)
	end

	-- =========================================================
	-- REPL: search existing REPL lines with Telescope if available
	-- =========================================================

	local function get_repl_buffer()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(buf)
				and vim.bo[buf].filetype == "dap-repl"
			then
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

		local ok, telescope_builtin = pcall(require, "telescope.builtin")

		if not ok then
			-- Telescope isn't installed: simply focus the REPL.
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win)
					and vim.api.nvim_win_get_buf(win) == repl_buf
				then
					vim.api.nvim_set_current_win(win)
					return
				end
			end

			vim.cmd("buffer " .. repl_buf)
			return
		end

		local lines = vim.api.nvim_buf_get_lines(repl_buf, 0, -1, false)

		if #lines == 0 then
			vim.notify("The DAP REPL is empty.", vim.log.levels.INFO)
			return
		end

		telescope_builtin.grep_string({
			search = "",
			search_dirs = {},
			grep_open_files = false,
			attach_mappings = function(prompt_bufnr, map)
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if not selection then
						return
					end

					for _, win in ipairs(vim.api.nvim_list_wins()) do
						if vim.api.nvim_win_is_valid(win)
							and vim.api.nvim_win_get_buf(win) == repl_buf
						then
							vim.api.nvim_set_current_win(win)
							vim.api.nvim_win_set_cursor(win, {
								selection.lnum or 1,
								0,
							})
							return
						end
					end

					vim.cmd("sbuffer " .. repl_buf)
					pcall(vim.api.nvim_win_set_cursor, 0, {
						selection.lnum or 1,
						0,
					})
				end)

				return true
			end,
		})
	end

	local function open_or_focus_repl()
		local repl_buf = get_repl_buffer()

		if repl_buf then
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win)
					and vim.api.nvim_win_get_buf(win) == repl_buf
				then
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
