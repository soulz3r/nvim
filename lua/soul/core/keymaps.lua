local keymap = vim.keymap.set
local OPTS = require("soul.core.helpers.keymaps").opts

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

keymap("n", "<leader>w", "<cmd>write<CR>", OPTS("Save"))

keymap("n", "<leader>cd", function()
	local file = vim.api.nvim_buf_get_name(0)

	if file == "" then
		return vim.notify("Current buffer has no file", vim.log.levels.WARN)
	end

	local directory = vim.fn.fnamemodify(file, ":h")
	vim.cmd.cd(vim.fn.fnameescape(directory))
	vim.notify(
		"Working directory: " .. vim.fn.fnamemodify(directory, ":~"),
		vim.log.levels.INFO,
		{ title = "Working Directory" }
	)
end, OPTS("Set cwd to current file directory"))
keymap("n", "<leader>q", "<cmd>quit<CR>", OPTS("Quit window"))

keymap("n", "<A-j>", ":m .+1<CR>==", OPTS("Move line down"))
keymap("n", "<A-k>", ":m .-2<CR>==", OPTS("Move line up"))

keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", OPTS("Move selection down"))
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", OPTS("Move selection up"))

keymap({ "i", "x" }, ",,", "<ESC>", OPTS())
keymap("n", ",,", "<CMD>nohl<CR>", OPTS("Clear highlight"))

keymap("t", "<C-;>", "<C-\\><C-n>", OPTS("Terminal Normal Mode"))

vim.cmd([[
  :amenu 10.100 mousemenu.Goto\ Definition <cmd>lua vim.lsp.buf.definition()<CR>
  :amenu 10.110 mousemenu.References <cmd>lua vim.lsp.buf.references()<CR>
  :amenu 10.120 mousemenu.-sep- *
]])

keymap("n", "<RightMouse>", "<cmd>:popup mousemenu<CR>")
keymap("n", "<Tab>", "<cmd>:popup mousemenu<CR>")

keymap("n", "<leader>x", function()
	local file = vim.api.nvim_buf_get_name(0)

	if file == "" then
		return vim.notify("Current buffer has no file", vim.log.levels.WARN)
	end

	local platform = require("soul.core.platform")

	if not platform.is_posix then
		return vim.notify("Windows does not use Unix executable permissions", vim.log.levels.WARN)
	end

	if vim.fn.executable("chmod") ~= 1 then
		return vim.notify("chmod was not found in PATH", vim.log.levels.ERROR)
	end

	local ok, process = pcall(vim.system, { "chmod", "+x", file }, { text = true })
	if not ok then
		return vim.notify("Could not start chmod: " .. tostring(process), vim.log.levels.ERROR)
	end

	local result = process:wait()
	if result.code ~= 0 then
		return vim.notify(vim.trim(result.stderr or "chmod failed"), vim.log.levels.ERROR)
	end

	vim.notify(
		"Made executable: " .. vim.fn.fnamemodify(file, ":t"),
		vim.log.levels.INFO,
		{ title = "File Permissions" }
	)
end, { desc = "Make executable" })

keymap("n", "<leader>ne", "<cmd>restart<cr>", { desc = "Restart Neovim" })
keymap("n", "<leader>ni", function()
	vim.cmd({
		cmd = "edit",
		args = { vim.fn.stdpath("config") .. "/init.lua" },
	})
end, { desc = "Open config" })
local function show_messages()
	local messages = vim.api.nvim_exec2("messages", { output = true }).output
	local Output = require("soul.core.helpers.ui.output")
	Output.open("Messages", messages, {
		filetype = "messages",
	})
end

keymap("n", "<leader>nm", show_messages, OPTS("Show messages in floating window"))

keymap("n", "<leader>X", function()
	require("soul.core.helpers.c_runner").run()
end, OPTS("Compile and run C file"))
keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("t", ",,", [[<C-\><C-n>]], {
	desc = "Terminal Normal Mode",
})
