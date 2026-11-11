local M = {}

local floats = require("soul.ui.floats")

local function dimensions(opts)
	local width = math.max(1, math.min(vim.o.columns - 4, opts.width or math.floor(vim.o.columns * 0.80)))
	local height = math.max(1, math.min(vim.o.lines - 4, opts.height or math.floor(vim.o.lines * 0.70)))
	return width, height
end

function M.create(title, initial, opts)
	opts = opts or {}

	local width, height = dimensions(opts)
	local row = math.max(0, math.floor((vim.o.lines - height) / 2))
	local col = math.max(0, math.floor((vim.o.columns - width) / 2))
	local lines = vim.deepcopy(initial or { "" })

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = opts.filetype or "text"

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = floats.border,
		title = " " .. (title or "Output") .. " ",
		title_pos = "center",
		width = width,
		height = height,
		row = row,
		col = col,
	})

	floats.apply(win)
	vim.wo[win].wrap = opts.wrap ~= false
	vim.wo[win].cursorline = true

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = buf, silent = true, nowait = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true, nowait = true })

	local output = {
		buf = buf,
		win = win,
	}

	function output.append(value)
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		if #current == 0 then
			current = { "" }
		end

		local addition = vim.split(tostring(value or ""), "\n", { plain = true })
		if #addition == 0 then
			return
		end

		local last = current[#current]
		current[#current] = last .. addition[1]
		for i = 2, #addition do
			table.insert(current, addition[i])
		end

		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, current)
		vim.bo[buf].modifiable = false

		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_cursor(win, { #current, 0 })
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

	function output.open_terminal(command, terminal_opts)
		if not vim.api.nvim_win_is_valid(win) then
			return
		end

		terminal_opts = terminal_opts or {}
		local term_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(win, term_buf)

		vim.bo[term_buf].bufhidden = "wipe"
		vim.bo[term_buf].swapfile = false

		local user_on_exit = terminal_opts.on_exit
		terminal_opts.on_exit = function(_, code, signal)
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(win) then
					output.set_title(("C Run · exit %d"):format(code))
				end
				if user_on_exit then
					user_on_exit(code, signal)
				end
			end)
		end

		vim.api.nvim_buf_call(term_buf, function()
			vim.fn.termopen(command, terminal_opts)
		end)

		vim.cmd.startinsert()
		return term_buf
	end

	return output
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
