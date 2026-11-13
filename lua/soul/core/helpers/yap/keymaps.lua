local M = {}
local actions = {}
local configured = false

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "YAP" })
end

local function prompt_arguments(root, executable, build_first)
	local directory = vim.fn.stdpath("data") .. "/yap/argument-history"
	vim.fn.mkdir(directory, "p")
	local key = vim.fn.sha256(vim.fs.normalize(root) .. "\\0" .. vim.fs.normalize(executable))
	local history_path = directory .. "/" .. key .. ".txt"
	local history = vim.fn.filereadable(history_path) == 1 and vim.fn.readfile(history_path) or {}

	vim.ui.input({
		prompt = "Arguments: ",
		default = history[#history] or "",
	}, function(input)
		if input == nil then
			return
		end

		local projects = require("yap.projects")
		local args, err = projects.parse_args(input)
		if not args then
			notify(err, vim.log.levels.ERROR)
			return
		end

		if input ~= "" then
			history = vim.tbl_filter(function(value)
				return value ~= input
			end, history)
			history[#history + 1] = input
			while #history > 100 do
				table.remove(history, 1)
			end
			vim.fn.writefile(history, history_path)
		end

		if build_first then
			projects.run(root, args)
		else
			projects.run_binary(executable, root, args)
		end
	end)
end

local function select_build_script()
	local projects = require("yap.projects")
	local root, scripts = projects.list_build_scripts()
	if #scripts == 0 then
		notify("No build scripts found in " .. root, vim.log.levels.WARN)
	elseif #scripts == 1 then
		projects.build(root, scripts[1])
	else
		vim.ui.select(scripts, { prompt = "Select project build script" }, function(script)
			if script then
				projects.build(root, script)
			end
		end)
	end
end

local function select_executable()
	local projects = require("yap.projects")
	local root, executables = projects.list_executables()
	if #executables == 0 then
		notify("No executables found in " .. root .. "/bin", vim.log.levels.WARN)
		return
	end

	vim.ui.select(executables, {
		prompt = "Select project executable",
		format_item = function(path)
			return vim.fn.fnamemodify(path, ":t")
		end,
	}, function(executable)
		if executable then
			prompt_arguments(root, executable, false)
		end
	end)
end

local function build_and_run()
	local projects = require("yap.projects")
	local root = projects.get_root()
	local executable = projects.project_executable(root)
	prompt_arguments(root, executable, true)
end

local function register(lhs, callback, description)
	actions[lhs] = callback
	vim.keymap.set("n", lhs, callback, {
		silent = true,
		noremap = true,
		desc = description,
	})
end

function M.setup()
	if configured then
		return
	end

	register("<leader>pp", function()
		require("telescope").extensions.project.project()
	end, "Open YAP project picker")
	register("<leader>pr", build_and_run, "Build and run current project")
	register("<leader>pb", function()
		require("yap.projects").build()
	end, "Build current project")
	register("<leader>pc", function()
		require("yap.projects").clean()
	end, "Clean current project")
	register("<leader>pB", function()
		require("yap.projects").rebuild()
	end, "Clean and rebuild current project")
	register("<leader>pS", select_build_script, "Select project build script")
	register("<leader>pe", select_executable, "Select project executable")
	register("<leader>ps", function()
		require("yap.projects").stop()
	end, "Stop project process")
	register("<leader>pR", function()
		require("yap.projects").rerun()
	end, "Rerun last project executable")

	configured = true
end

function M.run(lhs)
	local callback = actions[lhs]
	if type(callback) ~= "function" then
		notify("Project action is not ready: " .. lhs, vim.log.levels.ERROR)
		return
	end
	return callback()
end

return M
