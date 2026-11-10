keymap = vim.keymap.set

function OPTS(description)
	return {
		noremap = true,
		silent = true,
		desc = description or nil,
	}
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

keymap("n", "<Space>", "", OPTS())
keymap("n", "<C-i>", "<C-i>", OPTS())

keymap("n", "<C-h>", "<C-w>h", OPTS("Window left"))
keymap("n", "<C-j>", "<C-w>j", OPTS("Window down"))
keymap("n", "<C-k>", "<C-w>k", OPTS("Window up"))
keymap("n", "<C-l>", "<C-w>l", OPTS("Window right"))
keymap("n", "<m-tab>", "<c-6>", OPTS())

keymap("n", "<ma>", "<mA>", OPTS())

keymap("n", "n", "nzzzv", OPTS("Next search result"))
keymap("n", "N", "Nzzzv", OPTS("Previous search result"))
keymap("n", "*", "*zz", OPTS())
keymap("n", "#", "#zz", OPTS())
keymap("n", "g*", "g*zz", OPTS())
keymap("n", "g#", "g#zz", OPTS())

keymap({ "n", "o", "x" }, "<s-h>", "^", OPTS())
keymap({ "n", "o", "x" }, "<s-l>", "g_", OPTS())

keymap("v", "p", [["_dP]], { desc = "Paste without losing yank" })

keymap("n", "J", "mzJ`z", { desc = "Join lines" })
keymap("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })

keymap({ "n", "x" }, "j", "gj", OPTS())
keymap({ "n", "x" }, "k", "gk", OPTS())

keymap("n", "<leader>ww", ":w<CR>", OPTS("Save"))
keymap("n", "<leader>wa", ":w!<CR>", OPTS("Save force"))

keymap("n", "<leader>cd", function()
	local file = vim.api.nvim_buf_get_name(0)

	if file == "" then
		return vim.notify("Current buffer has no file", vim.log.levels.WARN)
	end

	local directory = vim.fn.fnamemodify(file, ":h")
	vim.cmd.cd(vim.fn.fnameescape(directory))
	vim.notify("Working directory: " .. vim.fn.fnamemodify(directory, ":~"))
end, OPTS("Set cwd to current file directory"))
keymap("n", "<leader>qq", ":q<CR>", OPTS("Quit"))
keymap("n", "<leader>qa", ":q!<CR>", OPTS("Quit without saving"))

keymap("n", "<A-j>", ":m .+1<CR>==", OPTS("Move line down"))
keymap("n", "<A-k>", ":m .-2<CR>==", OPTS("Move line up"))

keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", OPTS("Move selection down"))
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", OPTS("Move selection up"))

keymap({ "i", "x" }, ",,", "<ESC>", OPTS())
keymap("n", ",,", "<CMD>nohl<CR>", OPTS("Clear highlight"))

vim.api.nvim_set_keymap("t", "<C-;>", "<C-\\><C-n>", OPTS())

vim.cmd([[
  :amenu 10.100 mousemenu.Goto\ Definition <cmd>lua vim.lsp.buf.definition()<CR>
  :amenu 10.110 mousemenu.References <cmd>lua vim.lsp.buf.references()<CR>
  :amenu 10.120 mousemenu.-sep- *
]])

keymap("n", "<RightMouse>", "<cmd>:popup mousemenu<CR>")
keymap("n", "<Tab>", "<cmd>:popup mousemenu<CR>")

keymap("n", "<leader>c", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

keymap("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make executable" })

keymap("n", "<leader>ne", "<cmd>restart<cr>", { desc = "Restart Neovim" })
keymap("n", "<leader>ni", "<cmd>edit " .. vim.fn.stdpath("config") .. "/init.lua<CR>", { desc = "Open config" })
local function show_messages()
	local output = vim.api.nvim_exec2("messages", { output = true }).output
	local lines = vim.split(output, "\n", { plain = true })

	local width = math.min(vim.o.columns - 4, math.max(60, math.floor(vim.o.columns * 0.80)))
	local height = math.min(vim.o.lines - 4, math.max(8, math.floor(vim.o.lines * 0.70)))
	local row = math.floor((vim.o.lines - height) / 2 - 1)
	local col = math.floor((vim.o.columns - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "messages"

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		width = width,
		height = height,
		row = row,
		col = col,
	})

	vim.wo[win].wrap = true
	vim.wo[win].cursorline = true
	vim.api.nvim_win_set_cursor(win, { #lines, 0 })

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = buf, silent = true, nowait = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true, nowait = true })
end

keymap("n", "<leader>nm", show_messages, OPTS("Show messages in floating window"))

keymap("n", "<leader>u", function()
	vim.cmd.packadd("nvim.undotree")
	require("undotree").open()
end, { desc = "Undotree" })

keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
