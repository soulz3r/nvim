local M = {}

local floats = require("soul.ui.floats")

function M.open(title, content, opts)
	opts = opts or {}

	local lines
	if type(content) == "table" then
		lines = content
	else
		lines = vim.split(content or "", "\n", { plain = true })
	end

	if #lines == 0 then
		lines = { "No output." }
	end

	local width = math.max(1, math.min(vim.o.columns - 4, opts.width or math.floor(vim.o.columns * 0.80)))
	local height = math.max(1, math.min(vim.o.lines - 4, opts.height or math.floor(vim.o.lines * 0.70)))
	local row = math.max(0, math.floor((vim.o.lines - height) / 2))
	local col = math.max(0, math.floor((vim.o.columns - width) / 2))

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
	vim.api.nvim_win_set_cursor(win, { #lines, 0 })

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = buf, silent = true, nowait = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true, nowait = true })

	return win
end

return M
