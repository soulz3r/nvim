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

local function project_root(path)
	path = vim.fn.fnamemodify(path or vim.fn.getcwd(), ":p")
	return vim.fs.root(path, root_markers) or path
end

local function build_script(root)
	local scripts = paths.is_windows
		and { "build_all.bat", "build.bat", "build_all.sh", "build.sh" }
		or { "build_all.sh", "build.sh" }

	for _, name in ipairs(scripts) do
		local file = root .. "/" .. name
		if vim.fn.filereadable(file) == 1 then
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

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "log"
	vim.wo[win].wrap = true
	vim.wo[win].cursorline = true

	local function append(lines)
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
		vim.bo[buf].modifiable = false

		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
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

	append({ "Project: " .. root })

	return append
end

local function run_command(command, root, append, callback)
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
		on_exit = function(_, code)
			vim.schedule(function()
				callback(code)
			end)
		end,
	})

	if job <= 0 then
		append({ "Could not start process. jobstart returned " .. job })
		return false
	end

	return true
end

local function get_build_command(root, append)
	local script = build_script(root)

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

local function build(root, append, callback)
	local command = get_build_command(root, append)
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

function M.build(path)
	local root = project_root(path)
	local append = open_output(root, "Build Project")

	build(root, append, function() end)
end

function M.run(path)
	local root = project_root(path)
	local append = open_output(root, "Run Project")

	build(root, append, function(ok)
		if not ok then
			return
		end

		local executable = find_project_executable(root)
		if not executable then
			append({
				"",
				"Build completed, but the expected executable was not found:",
				"bin/" .. vim.fn.fnamemodify(root, ":t")
					.. (paths.is_windows and ".exe" or ""),
			})
			return
		end

		append({ "", "Launching: " .. vim.fn.fnamemodify(executable, ":.") })
		launch(executable, root, append)
	end)
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

function M.run_executable(path)
	local root = project_root(path)
	local executables = find_bin_executables(root)

	if #executables == 0 then
		vim.notify("No executables found in " .. root .. "/bin", vim.log.levels.WARN)
		return
	end

	vim.ui.select(executables, {
		prompt = "Select executable:",
		format_item = function(file)
			return vim.fn.fnamemodify(file, ":t")
		end,
	}, function(choice)
		if not choice then
			return
		end

		vim.ui.input({
			prompt = "Arguments: ",
		}, function(input)
			if input == nil then
				return
			end

			local args, err = parse_args(input)
			if not args then
				vim.notify(err, vim.log.levels.ERROR)
				return
			end

			local append = open_output(root, "Run Executable")
			append({ "Executable: " .. vim.fn.fnamemodify(choice, ":t") })
			launch(choice, root, append, args)
		end)
	end)
end

return M
