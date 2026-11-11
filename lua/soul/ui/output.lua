local M = {}

local floats = require("soul.ui.floats")

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

local function map_close_keys(buf, close)
	vim.keymap.set("n", "q", close, { buffer = buf, silent = true, nowait = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true, nowait = true })
end

function M.create(title, initial, opts)
	opts = opts or {}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.deepcopy(initial or { "" }))
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

	-- Show the floating terminal before starting the child process.
	vim.cmd("redraw!")

	vim.wo[win].wrap = false
	vim.wo[win].cursorline = false
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"

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

	map_close_keys(buf, close)
	vim.keymap.set("t", "<C-q>", close, { buffer = buf, silent = true, nowait = true })

	vim.api.nvim_create_autocmd("BufHidden", {
		buffer = buf,
		once = true,
		callback = function()
			if vim.fn.bufwinid(buf) == -1 then
				stop()
			end
		end,
	})

	local user_on_exit = opts.on_exit
	opts.on_exit = function(_, code, event)
		vim.schedule(function()
			job = nil
			if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf) then
				local config = vim.api.nvim_win_get_config(win)
				config.title = (" %s · exit %d "):format(title or "Terminal", code or -1)
				vim.api.nvim_win_set_config(win, config)
			end

			if user_on_exit then
				user_on_exit(code, event)
			end
		end)
	end

	local ok, result = pcall(vim.api.nvim_win_call, win, function()
		return vim.fn.termopen(command, opts)
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
	vim.api.nvim_set_current_win(win)
	vim.cmd.startinsert()
	return {
		buf = buf,
		win = win,
		job = job,
		close = close,
	}
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
