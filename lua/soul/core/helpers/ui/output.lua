local M = {}

local floats = require("soul.core.helpers.ui.floats")

local function dimensions(opts)
	local width = math.max(1, math.min(vim.o.columns - 4, opts.width or math.floor(vim.o.columns * 0.80)))
	local height = math.max(1, math.min(vim.o.lines - 4, opts.height or math.floor(vim.o.lines * 0.70)))
	return width, height
end

local function window_config(title, opts)
	local width, height = dimensions(opts)
	return {
		relative = "editor",
		style = "minimal",
		border = floats.border,
		title = " " .. (title or "Output") .. " ",
		title_pos = "center",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2)),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
	}
end

local function normalize_lines(lines)
	local normalized = {}

	for _, value in ipairs(lines or {}) do
		local parts = vim.split(tostring(value or ""):gsub("\r\n", "\n"):gsub("\r", "\n"), "\n", {
			plain = true,
		})

		for _, line in ipairs(parts) do
			table.insert(normalized, line)
		end
	end

	if #normalized == 0 then
		return { "" }
	end

	return normalized
end

local function map_close_keys(buf, close)
	vim.keymap.set("n", "q", close, { buffer = buf, silent = true, nowait = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true, nowait = true })
end

function M.create(title, initial, opts)
	opts = opts or {}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, normalize_lines(vim.deepcopy(initial or { "" })))
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = opts.filetype or "text"

	local win = vim.api.nvim_open_win(buf, true, window_config(title, opts))
	floats.apply(win)
	vim.wo[win].wrap = opts.wrap ~= false
	vim.wo[win].cursorline = true

	local output = {
		buf = buf,
		win = win,
	}

	function output.is_open()
		return vim.api.nvim_win_is_valid(win)
	end

	function output.close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	function output.append(value)
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		if #lines == 0 then
			lines = { "" }
		end

		local addition = vim.split(tostring(value or ""), "\n", { plain = true })
		lines[#lines] = lines[#lines] .. addition[1]
		for i = 2, #addition do
			table.insert(lines, addition[i])
		end

		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false

		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_cursor(win, { #lines, 0 })
		end
	end

	function output.set_title(value)
		if not vim.api.nvim_win_is_valid(win) then
			return
		end

		local config = vim.api.nvim_win_get_config(win)
		config.title = " " .. value .. " "
		vim.api.nvim_win_set_config(win, config)
	end

	map_close_keys(buf, output.close)
	return output
end

function M.terminal(title, command, opts)
	opts = opts or {}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false

	local win = vim.api.nvim_open_win(buf, true, window_config(title or "Terminal", opts))
	floats.apply(win)
	vim.cmd("redraw!")

	vim.wo[win].wrap = opts.wrap ~= false
	vim.wo[win].linebreak = true
	vim.wo[win].breakindent = true
	vim.wo[win].cursorline = false
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"

	local markers = opts.highlight_markers
	local job_opts = vim.tbl_extend("force", {}, opts)
	job_opts.highlight_markers = nil

	local on_exit = job_opts.on_exit
	job_opts.on_exit = function(job_id, exit_code, event)
		if on_exit then
			on_exit(job_id, exit_code, event)
		end

		vim.schedule(function()
			if
				vim.api.nvim_buf_is_valid(buf)
				and vim.api.nvim_get_current_buf() == buf
				and vim.fn.mode(1):sub(1, 1) == "t"
			then
				vim.cmd.stopinsert()
			end
		end)
	end

	if type(markers) == "table" and next(markers) ~= nil then
		local namespace = vim.api.nvim_create_namespace("SoulOutputTerminal")
		vim.api.nvim_buf_attach(buf, false, {
			on_lines = function(_, changed_buf, _, firstline, _, new_lastline)
				if not vim.api.nvim_buf_is_valid(changed_buf) then
					return true
				end

				local lines = vim.api.nvim_buf_get_lines(changed_buf, firstline, new_lastline, false)
				local matches = {}

				for offset, line in ipairs(lines) do
					local normalized = line:gsub("\r$", "")
					local group = markers[normalized]
					if group then
						table.insert(matches, {
							row = firstline + offset - 1,
							line = normalized,
							group = group,
						})
					end
				end

				if #matches > 0 then
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(changed_buf) then
							return
						end

						for _, match in ipairs(matches) do
							local current = vim.api.nvim_buf_get_lines(changed_buf, match.row, match.row + 1, false)[1]
							if current and current:gsub("\r$", "") == match.line then
								vim.api.nvim_buf_set_extmark(changed_buf, namespace, match.row, 0, {
									end_row = match.row,
									end_col = #current,
									hl_group = match.group,
									priority = 200,
								})
							end
						end
					end)
				end
			end,
		})
	end

	local job

	local function stop()
		if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
			vim.fn.jobstop(job)
		end
		job = nil
	end

	local function close()
		stop()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, {
		buffer = buf,
		silent = true,
		nowait = true,
		desc = "Close output terminal",
	})

	local terminal = {
		buf = buf,
		win = win,
	}

	function terminal.is_open()
		return vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf)
	end

	function terminal.send(value)
		if not terminal.is_open() or not job then
			return false
		end

		local ok = pcall(vim.api.nvim_chan_send, job, value)
		return ok
	end

	function terminal.set_title(value)
		if not terminal.is_open() then
			return
		end

		local config = vim.api.nvim_win_get_config(win)
		config.title = " " .. value .. " "
		vim.api.nvim_win_set_config(win, config)
	end

	function terminal.close()
		close()
	end

	vim.api.nvim_create_autocmd("BufHidden", {
		buffer = buf,
		once = true,
		callback = function()
			if vim.fn.bufwinid(buf) == -1 then
				stop()
			end
		end,
	})

	local ok, result = pcall(vim.api.nvim_win_call, win, function()
		return vim.fn.termopen(command, job_opts)
	end)

	if not ok or type(result) ~= "number" or result <= 0 then
		local message = ok and ("termopen failed with job id " .. tostring(result)) or tostring(result)
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		return nil, message
	end

	job = result
	terminal.job = job
	vim.api.nvim_set_current_win(win)
	vim.cmd.startinsert()
	return terminal
end

function M.open(title, content, opts)
	local lines
	if type(content) == "table" then
		lines = content
	else
		lines = vim.split(content or "", "\n", { plain = true })
	end

	if #lines == 0 then
		lines = { "No output." }
	end

	return M.create(title, lines, opts)
end

return M
