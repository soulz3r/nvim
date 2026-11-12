local M = {}

function M.setup(dap, projects, args, platform, paths)
	local fn = vim.fn

	dap.adapters.lldb = {
		type = "executable",
		command = paths.lldb_dap,
		name = "lldb",
	}

	local function make_config(root, executable, launch_args, name)
		return {
			name = name or "Launch executable",
			type = "lldb",
			request = "launch",
			program = executable,
			cwd = root,
			args = launch_args or {},
			stopOnEntry = false,
			runInTerminal = false,
		}
	end

	local function configured_program()
		local entry, root = projects.current()
		if not entry or not root then
			return nil
		end

		if projects.is_executable(entry.executable) then
			return entry.executable
		end

		local candidates = projects.find_executables(root)
		if #candidates == 1 then
			projects.save_executable(root, candidates[1])
			return candidates[1]
		end

		vim.notify(
			#candidates > 1 and "Multiple executables found. Use <leader>dc to choose one."
				or "No executable found for this project. Use <leader>de to configure one.",
			vim.log.levels.WARN
		)
		return nil
	end

	local function dynamic_config(launch_args)
		return {
			name = "Launch current project",
			type = "lldb",
			request = "launch",
			program = configured_program,
			cwd = function()
				local _, root = projects.current()
				return root or fn.getcwd()
			end,
			args = launch_args or {},
			stopOnEntry = false,
			runInTerminal = false,
		}
	end

	dap.configurations.c = {
		dynamic_config({}),
		dynamic_config({ "tree" }),
	}
	dap.configurations.cpp = dap.configurations.c
	dap.configurations.rust = dap.configurations.c
	dap.defaults.fallback.switchbuf = "useopen"

	local function prompt_arguments(callback)
		local entry, root = projects.current()
		if not entry or not root then
			vim.notify("Could not resolve a project for launch arguments.", vim.log.levels.ERROR)
			return
		end

		vim.ui.input({
			prompt = "Program arguments: ",
			default = args.format(entry.args or {}),
		}, function(input)
			if input == nil then
				return
			end

			local parsed, parse_error = args.parse(input, platform.is_windows)
			if not parsed then
				vim.notify(parse_error, vim.log.levels.ERROR)
				return
			end

			if not projects.save_args(root, parsed) then
				return
			end
			callback(parsed)
		end)
	end

	local function start_or_continue()
		if dap.session() then
			dap.continue()
			return
		end

		local entry, root = projects.current()
		if not entry or not root then
			vim.notify("Could not resolve a project for the current file.", vim.log.levels.ERROR)
			return
		end

		local function launch(executable)
			if not projects.is_executable(executable) then
				vim.notify("Executable not found:\n" .. tostring(executable), vim.log.levels.ERROR)
				return
			end

			projects.save_executable(root, executable)
			prompt_arguments(function(launch_args)
				dap.run(make_config(root, executable, launch_args, "Launch " .. fn.fnamemodify(executable, ":t")))
			end)
		end

		if projects.is_executable(entry.executable) then
			launch(entry.executable)
			return
		end

		local candidates = projects.find_executables(root)
		if #candidates == 1 then
			launch(candidates[1])
			return
		end

		if #candidates > 1 then
			vim.ui.select(candidates, {
				prompt = "Choose executable for " .. root,
				format_item = function(candidate)
					return fn.fnamemodify(candidate, ":~:.")
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

	return {
		start_or_continue = start_or_continue,
	}
end

return M
