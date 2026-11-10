-- lua/soul/core/projects.lua
local M = {}

local paths = require("soul.core.paths")

local root_markers = {
	".git",
	"build.sh",
	"build.bat",
	"build_all.sh",
	"build_all.bat",
	"compile_commands.json",
	"compile_flags.txt",
	"CMakeLists.txt",
}

local active_job
local last_run

local function project_root(path)
	path = vim.fn.fnamemodify(path or vim.fn.getcwd(), ":p")

	if vim.fn.isdirectory(path) ~= 1 then
		path = vim.fs.dirname(path)
	end

	return vim.fs.root(path, root_markers) or path
end

local function stop_active_job()
	if not active_job then
		return false
	end

	local job = active_job
	local stopped = vim.fn.jobstop(job)

	if stopped > 0 then
		return true
	end

	active_job = nil
	return false
end

local function list_build_scripts(root)
	local patterns = paths.is_windows and { "build*.bat", "build*.sh" } or { "build*.sh" }
	local found = {}

	for _, pattern in ipairs(patterns) do
		for _, file in ipairs(vim.fn.globpath(root, pattern, false, true)) do
			if vim.fn.filereadable(file) == 1 then
				found[#found + 1] = vim.fn.fnamemodify(file, ":t")
			end
		end
	end

	table.sort(found)
	return found
end

local function build_script(root, selected)
	if selected and vim.fn.filereadable(root .. "/" .. selected) == 1 then
		return selected
	end

	local scripts = paths.is_windows
		and { "build_all.bat", "build.bat", "build_all.sh", "build.sh" }
		or { "build_all.sh", "build.sh" }

	for _, name in ipairs(scripts) do
		if vim.fn.filereadable(root .. "/" .. name) == 1 then
			return name
		end
	end
end

local function clean_script(root)
	local scripts = paths.is_windows
		and { "clean_all.bat", "clean.bat", "clean_all.sh", "clean.sh" }
		or { "clean_all.sh", "clean.sh" }

	for _, name in ipairs(scripts) do
		if vim.fn.filereadable(root .. "/" .. name) == 1 then
			return name
		end
	end
end

local function script_command(script)
	if script:match("%.bat$") then
		local cmd = vim.fn.exepath("cmd.exe")
		if cmd == "" then
			cmd = "cmd.exe"
		end

		return { cmd, "/d", "/c", "call", script }
	end

	local shell = vim.fn.exepath("bash")
	if shell == "" then
		shell = vim.fn.exepath("sh")
	end

	if shell == "" then
		return nil
	end

	return { shell, "./" .. script }
end

local function open_output(root, title)
	local output_lines = {}
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.82)))
	local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.72)))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
	})

	vim.bo[buf].bufhidden = "wipe"
	local terminal = vim.api.nvim_open_term(buf, {})
	vim.wo[win].wrap = true
	vim.wo[win].cursorline = true
	vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle"

	local function append(lines)
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		for _, line in ipairs(lines) do
			output_lines[#output_lines + 1] = line
		end

		vim.api.nvim_chan_send(terminal, table.concat(lines, "\r\n") .. "\r\n")

		if vim.api.nvim_win_is_valid(win) then
			local line_count = vim.api.nvim_buf_line_count(buf)
			vim.api.nvim_win_set_cursor(win, { line_count, 0 })
		end
	end

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, close, {
			buffer = buf,
			silent = true,
			nowait = true,
			desc = "Close project output",
		})
	end

	vim.keymap.set("n", "<C-c>", function()
		if not stop_active_job() then
			vim.notify("No project process is running.", vim.log.levels.INFO)
		end
	end, {
		buffer = buf,
		silent = true,
		desc = "Stop project process",
	})

	vim.keymap.set("n", "<leader>pq", function()
		local items = {}

		for _, line in ipairs(output_lines) do
			local filename, row, column, severity, message =
				line:match("^(.-):(%d+):(%d+):%s*([^:]+):%s*(.*)$")

			if not filename then
				filename, row, column, severity, message =
					line:match("^(.-)%((%d+),(%d+)%)%s*:%s*([^:]+):%s*(.*)$")
			end

			if filename and row and column then
				local absolute = (filename:match("^%a:[/\\\\]") or filename:match("^[/\\\\]"))
					and filename
					or (root .. "/" .. filename)

				items[#items + 1] = {
					filename = absolute,
					lnum = tonumber(row),
						col = tonumber(column),
						text = severity .. ": " .. message,
				}
			end
		end

		if #items == 0 then
			vim.notify("No compiler diagnostics found in project output.", vim.log.levels.INFO)
			return
		end

		vim.fn.setqflist({}, " ", {
			title = "Project Diagnostics",
			items = items,
		})
		vim.cmd.copen()
	end, {
		buffer = buf,
		silent = true,
		desc = "Open project diagnostics",
	})

	append({ "Project: " .. root })

	return append
end

local function run_command(command, root, append, callback)
	if active_job and vim.fn.jobwait({ active_job }, 0)[1] == -1 then
		append({ "", "Another project process is already running.", "Stop it before starting another." })
		return false
	end

	active_job = nil
	append({ "", "$ " .. table.concat(command, " ") })

	local job = vim.fn.jobstart(command, {
		cwd = root,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.schedule(function()
					if #data > 0 then
						append(data)
					end
				end)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.schedule(function()
					if #data > 0 then
						append(data)
					end
				end)
			end
		end,
		on_exit = function(job_id, code)
			vim.schedule(function()
				if active_job == job_id then
					active_job = nil
				end

				callback(code)
			end)
		end,
	})

	if job <= 0 then
		append({ "Could not start process. jobstart returned " .. job })
		return false
	end

	active_job = job
	return true
end

local function get_build_command(root, append, selected_script)
	local script = build_script(root, selected_script)

	if not script then
		append({
			"",
			"No supported build script found.",
			"Expected build.sh, build.bat, build_all.sh, or build_all.bat.",
		})
		return nil
	end

	local command = script_command(script)
	if not command then
		append({ "", "No sh or bash executable was found to run " .. script })
		return nil
	end

	append({ "Build script: " .. script })
	return command
end

local function find_project_executable(root)
	local name = vim.fn.fnamemodify(root, ":t")
	local executable = root .. "/bin/" .. name

	if paths.is_windows then
		executable = executable .. ".exe"
	end

	if vim.fn.filereadable(executable) == 1 then
		return executable
	end
end

local function find_bin_executables(root)
	local bin = root .. "/bin"
	if vim.fn.isdirectory(bin) ~= 1 then
		return {}
	end

	local found = {}
	for _, file in ipairs(vim.fn.glob(bin .. "/*", false, true)) do
		if vim.fn.isdirectory(file) == 0 then
			local valid = paths.is_windows
				and file:lower():match("%.exe$") ~= nil
				or (not paths.is_windows and vim.fn.executable(file) == 1)

			if valid then
				found[#found + 1] = file
			end
		end
	end

	table.sort(found)
	return found
end

local function launch(file, root, append, args)
	last_run = {
		file = file,
		root = root,
		args = vim.deepcopy(args or {}),
	}

	local command = { file }
	vim.list_extend(command, args or {})

	run_command(command, root, append, function(code)
		append({
			"",
			code == 0 and "Process finished successfully."
				or ("Process exited with code " .. code),
		})
	end)
end

local function build(root, append, callback, selected_script)
	local command = get_build_command(root, append, selected_script)
	if not command then
		return
	end

	run_command(command, root, append, function(code)
		if code == 0 then
			append({ "", "Build succeeded." })
			callback(true)
		else
			append({ "", "Build failed. Exit code: " .. code })
			callback(false)
		end
	end)
end

local function clean(root, append, callback)
	local script = clean_script(root)

	if not script then
		append({ "", "No clean script found. Expected clean.sh or clean.bat." })
		callback(false, false)
		return
	end

	local command = script_command(script)
	if not command then
		append({ "", "No sh or bash executable was found to run " .. script })
		callback(false, true)
		return
	end

	append({ "Clean script: " .. script })
	run_command(command, root, append, function(code)
		if code == 0 then
			append({ "", "Clean succeeded." })
		else
			append({ "", "Clean failed. Exit code: " .. code })
		end

		callback(code == 0, true)
	end)
end

function M.stop()
	if not stop_active_job() then
		vim.notify("No project process is running.", vim.log.levels.INFO)
	end
end

function M.build(path, selected_script)
	local root = project_root(path)
	local append = open_output(root, "Build Project")

	build(root, append, function() end, selected_script)
end

function M.clean(path)
	local root = project_root(path)
	local append = open_output(root, "Clean Project")

	clean(root, append, function(ok, found)
		if not found then
			vim.notify("No clean script found for this project.", vim.log.levels.WARN)
		end
	end)
end

function M.rebuild(path)
	local root = project_root(path)
	local append = open_output(root, "Rebuild Project")

	clean(root, append, function(ok, found)
		if found and not ok then
			return
		end

		build(root, append, function() end)
	end)
end

function M.run(path, args, selected_script)
	local root = project_root(path)
	local append = open_output(root, "Run Project")

	build(root, append, function(ok)
		if not ok then
			return
		end

		local executable = find_project_executable(root)
		local available = find_bin_executables(root)

		if not executable and #available == 1 then
			executable = available[1]
		end

		if not executable then
			append({
				"",
				"Could not determine which executable to run.",
				"Expected: bin/" .. vim.fn.fnamemodify(root, ":t")
					.. (paths.is_windows and ".exe" or ""),
			})

			if #available > 1 then
				append({ "Multiple executables found. Use <leader>pe to select one:" })
				for _, file in ipairs(available) do
					append({ "  " .. vim.fn.fnamemodify(file, ":t") })
				end
			end

			return
		end

		append({ "", "Launching: " .. vim.fn.fnamemodify(executable, ":.") })
		launch(executable, root, append, args)
	end, selected_script)
end

local function parse_args(input)
	local args = {}
	local current = {}
	local quote = nil
	local escaped = false
	local token_started = false

	for i = 1, #input do
		local char = input:sub(i, i)

		if escaped then
			current[#current + 1] = char
			escaped = false
		elseif char == "\\" and quote ~= "'" then
			local next_char = input:sub(i + 1, i + 1)

			if next_char == '"' or next_char == "'" or next_char == "\\" or next_char:match("%s") then
				escaped = true
				token_started = true
			else
				current[#current + 1] = char
				token_started = true
			end
		elseif quote then
			if char == quote then
				quote = nil
			else
				current[#current + 1] = char
			end
			token_started = true
		elseif char == "'" or char == '"' then
			quote = char
			token_started = true
		elseif char:match("%s") then
			if token_started then
				args[#args + 1] = table.concat(current)
				current = {}
				token_started = false
			end
		else
			current[#current + 1] = char
			token_started = true
		end
	end

	if escaped then
		current[#current + 1] = "\\"
	end

	if quote then
		return nil, "Unclosed quote in arguments."
	end

	if token_started then
		args[#args + 1] = table.concat(current)
	end

	return args
end

function M.get_root(path)
	return project_root(path)
end

function M.list_build_scripts(path)
	local root = project_root(path)
	return root, list_build_scripts(root)
end

function M.list_executables(path)
	local root = project_root(path)
	return root, find_bin_executables(root)
end

function M.project_executable(path)
	local root = project_root(path)
	local executable = find_project_executable(root)

	if executable then
		return executable
	end

	local available = find_bin_executables(root)
	if #available == 1 then
		return available[1]
	end

	return root .. "/bin/" .. vim.fn.fnamemodify(root, ":t") .. (paths.is_windows and ".exe" or "")
end

function M.parse_args(input)
	return parse_args(input)
end

function M.run_binary(file, root, args)
	local append = open_output(root, "Run Executable")
	append({ "Executable: " .. vim.fn.fnamemodify(file, ":t") })
	launch(file, root, append, args)
end

function M.rerun()
	if not last_run then
		vim.notify("No previous project executable to rerun.", vim.log.levels.INFO)
		return
	end

	local previous = vim.deepcopy(last_run)
	M.run_binary(previous.file, previous.root, previous.args)
end

return M
