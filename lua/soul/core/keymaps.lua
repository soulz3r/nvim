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

keymap("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make executable" })

keymap("n", "<leader>ne", "<cmd>restart<cr>", { desc = "Restart Neovim" })
keymap("n", "<leader>ni", "<cmd>edit " .. vim.fn.stdpath("config") .. "/init.lua<CR>", { desc = "Open config" })
local Output = require("soul.ui.output")

local function show_messages()
	local messages = vim.api.nvim_exec2("messages", { output = true }).output
	Output.open("Messages", messages, {
		filetype = "messages",
	})
end

keymap("n", "<leader>nm", show_messages, OPTS("Show messages in floating window"))

local function compile_and_run_c()
	local function show_error(message)
		Output.open("C Build / Run", {
			"COMPILATION ERROR",
			"",
			tostring(message),
		}, {
			filetype = "compiler",
			wrap = true,
		})
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

	local clang = vim.fn.exepath("clang")
	if clang == "" then
		return show_error("clang was not found in PATH")
	end

	local directory = vim.fn.fnamemodify(file, ":h")
	local executable = vim.fn.fnamemodify(file, ":r")
	local is_windows = vim.fn.has("win32") == 1

	if is_windows then
		executable = executable .. ".exe"
	end

	-- cmd.exe does not understand the single-quote escaping used by shellescape().
	-- Use a temporary batch file so paths containing spaces are handled correctly.
	local terminal_command
	local terminal_opts = {
		cwd = directory,
	}

	if is_windows then
		local function batch_quote(path)
			return '"' .. path:gsub("%%", "%%%%") .. '"'
		end

		local script = vim.fn.tempname() .. ".cmd"
		local lines = {
			"@echo off",
			"setlocal DisableDelayedExpansion",
			table.concat({
				batch_quote(clang),
				"-std=c23 -g -O0 -o",
				batch_quote(executable),
				batch_quote(file),
			}, " "),
			"if errorlevel 1 exit /b %errorlevel%",
			batch_quote(executable),
			"exit /b %errorlevel%",
		}

		local written, write_error = pcall(vim.fn.writefile, lines, script)
		if not written then
			return show_error("Could not create build script:\n" .. tostring(write_error))
		end

		terminal_command = {
			"cmd.exe",
			"/d",
			"/q",
			"/c",
			'call "' .. script .. '"',
		}

		terminal_opts.on_exit = function()
			vim.schedule(function()
				vim.fn.delete(script)
			end)
		end
	else
		local command = table.concat({
			vim.fn.shellescape(clang),
			"-std=c23 -g -O0 -o",
			vim.fn.shellescape(executable),
			vim.fn.shellescape(file),
			"&&",
			"exec",
			vim.fn.shellescape(executable),
		}, " ")

		terminal_command = { "/bin/sh", "-c", command }
	end

	local terminal, terminal_error = Output.terminal("C Run", terminal_command, terminal_opts)

	if not terminal then
		show_error("Could not start the floating terminal:\n" .. tostring(terminal_error))
	end
end

keymap("n", "<leader>X", compile_and_run_c, OPTS("Compile and run C file"))

keymap("n", "<leader>u", function()
	vim.cmd.packadd("nvim.undotree")
	require("undotree").open()
end, { desc = "Undotree" })

keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
