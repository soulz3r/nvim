local M = {}

local Output = require("soul.core.helpers.ui.output")
local paths = require("soul.core.helpers.paths")
local platform = require("soul.core.platform")

local compilation_error_namespace = vim.api.nvim_create_namespace("SoulCompilationError")

function M.run()
	local function show_error(message)
		local output = Output.open("C Build / Run", {
			"COMPILATION ERROR",
			"",
			tostring(message),
		}, {
			filetype = "compiler",
			wrap = true,
		})

		if output and vim.api.nvim_buf_is_valid(output.buf) then
			vim.api.nvim_buf_set_extmark(output.buf, compilation_error_namespace, 0, 0, {
				end_row = 0,
				end_col = #"COMPILATION ERROR",
				hl_group = "SoulError",
				priority = 200,
			})
		end
	end

	local file = vim.api.nvim_buf_get_name(0)

	if file == "" then
		return show_error("Current buffer has no file")
	end

	if vim.bo.filetype ~= "c" then
		return show_error("Current buffer is not a C file")
	end

	local saved, save_error = pcall(vim.cmd, "silent update")
	if not saved then
		return show_error(save_error)
	end

	local clang = paths.clang
	if vim.fn.executable(clang) ~= 1 then
		return show_error("clang was not found in PATH")
	end

	local directory = vim.fn.fnamemodify(file, ":h")
	local executable = vim.fn.fnamemodify(file, ":r")

	if platform.is_windows then
		executable = executable .. ".exe"
	end

	-- Build the command display from the same arguments passed to Clang.
	-- Its separators and wrapped lines use the floating window's actual width.
	local float_width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.80)))
	local function separator(label)
		local remaining = math.max(2, float_width - #label - 2)
		local left = math.floor(remaining / 2)
		local right = remaining - left
		return string.rep("=", left) .. " " .. label .. " " .. string.rep("=", right)
	end

	local build_marker = separator("COMPILATION")
	local execution_marker = separator("EXECUTION")
	local terminal_command
	local terminal_opts = {
		cwd = directory,
		highlight_markers = {
			[build_marker] = "SoulBuildSeparator",
			[execution_marker] = "SoulExecutionSeparator",
			["Compilation successful."] = "SoulSuccess",
			["Compilation failed."] = "SoulError",
		},
	}

	if platform.is_windows then
		local powershell = paths.resolve_powershell()

		if not powershell or powershell == "pwsh" then
			return show_error(
				"PowerShell 7 could not be resolved. Set PWSH to the full path of pwsh.exe or add its install directory to PATH.\nResolved candidate: "
					.. tostring(powershell)
			)
		end

		local function ps_quote(value)
			return "'" .. value:gsub("'", "''") .. "'"
		end

		local script = vim.fn.tempname() .. ".ps1"
		local compile_command = table.concat({
			ps_quote(clang),
			"'-std=c23'",
			"'-g'",
			"'-O0'",
			"'-o'",
			ps_quote(executable),
			ps_quote(file),
		}, " ")

		local words = {}
		local current = {}
		local quoted = false
		for i = 1, #compile_command do
			local char = compile_command:sub(i, i)
			if char == "'" then
				quoted = not quoted
			end
			if char:match("%s") and not quoted then
				if #current > 0 then
					table.insert(words, table.concat(current))
					current = {}
				end
			else
				table.insert(current, char)
			end
		end
		if #current > 0 then
			table.insert(words, table.concat(current))
		end

		local command_lines = {}
		local line = "> "
		local continuation = "  "
		for _, word in ipairs(words) do
			local candidate = line == "> " and (line .. word) or (line .. " " .. word)
			if vim.fn.strdisplaywidth(candidate) > float_width and line ~= "> " then
				table.insert(command_lines, line)
				line = continuation .. word
			else
				line = candidate
			end
		end
		table.insert(command_lines, line)

		for _, command_line in ipairs(command_lines) do
			terminal_opts.highlight_markers[command_line] = "SoulMuted"
		end

		local lines = {
			"Write-Output " .. ps_quote(build_marker),
		}
		for _, command_line in ipairs(command_lines) do
			table.insert(lines, "Write-Output " .. ps_quote(command_line))
		end
		table.insert(lines, "& " .. compile_command)
		table.insert(lines, "$compileExitCode = $LASTEXITCODE")
		table.insert(lines, "if ($compileExitCode -ne 0) {")
		table.insert(lines, "\tWrite-Output 'Compilation failed.'")
		table.insert(lines, "\tWrite-Output ('Exit code: ' + $compileExitCode)")
		table.insert(lines, "\texit $compileExitCode")
		table.insert(lines, "}")
		table.insert(lines, "Write-Output 'Compilation successful.'")
		table.insert(lines, "Write-Output ''")
		table.insert(lines, "Write-Output " .. ps_quote(execution_marker))
		table.insert(lines, "& " .. ps_quote(executable))
		table.insert(lines, "exit $LASTEXITCODE")

		local ok, result = pcall(vim.fn.writefile, lines, script)
		if not ok or result ~= 0 then
			vim.fn.delete(script)
			return show_error("Could not create PowerShell script:\n" .. tostring(result))
		end

		terminal_command = {
			powershell,
			"-NoLogo",
			"-NoProfile",
			"-ExecutionPolicy",
			"Bypass",
			"-File",
			script,
		}

		terminal_opts.on_exit = function()
			vim.schedule(function()
				vim.fn.delete(script)
			end)
		end
	elseif platform.is_linux or platform.is_wsl or platform.is_macos or platform.is_termux then
		local compile_args = {
			vim.fn.shellescape(clang),
			"-std=c23",
			"-g",
			"-O0",
			"-o",
			vim.fn.shellescape(executable),
			vim.fn.shellescape(file),
		}
		local compile_command = table.concat(compile_args, " ")
		local command = table.concat({
			"printf '%s\\n' " .. vim.fn.shellescape(build_marker),
			"printf '%s\\n' " .. vim.fn.shellescape("> " .. compile_command),
			compile_command,
			"compile_exit_code=$?",
			'if [ "$compile_exit_code" -ne 0 ]; then printf \'Compilation failed.\\nExit code: %s\\n\' "$compile_exit_code"; exit "$compile_exit_code"; fi',
			"printf '%s\\n' 'Compilation successful.'",
			"printf '\\n%s\\n' " .. vim.fn.shellescape(execution_marker),
			"exec " .. vim.fn.shellescape(executable),
		}, "; ")

		local shell = "/bin/sh"
		if platform.is_termux then
			shell = vim.fn.exepath("sh")
			if shell == "" then
				shell = "/system/bin/sh"
			end
		end

		if vim.fn.executable(shell) ~= 1 then
			return show_error("POSIX shell was not found")
		end

		terminal_command = { shell, "-c", command }
	else
		return show_error("The C runner does not support this platform: " .. platform.name)
	end

	local terminal, terminal_error = Output.terminal("C Run", terminal_command, terminal_opts)

	if not terminal then
		show_error("Could not start the floating terminal:\n" .. tostring(terminal_error))
	end
end

return M
