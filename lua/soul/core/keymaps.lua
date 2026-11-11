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
	local file = vim.api.nvim_buf_get_name(0)

	if file == "" then
		return vim.notify("Current buffer has no file", vim.log.levels.WARN, { title = "C Build" })
	end

	if vim.bo.filetype ~= "c" then
		return vim.notify("Current buffer is not a C file", vim.log.levels.WARN, { title = "C Build" })
	end

	local saved, save_error = pcall(vim.cmd, "silent update")
	if not saved then
		return vim.notify(save_error, vim.log.levels.ERROR, { title = "C Build" })
	end

	local clang = vim.fn.exepath("clang")
	if clang == "" then
		return vim.notify("clang was not found in PATH", vim.log.levels.ERROR, { title = "C Build" })
	end

	local directory = vim.fn.fnamemodify(file, ":h")
	local executable = vim.fn.fnamemodify(file, ":r")
	if vim.fn.has("win32") == 1 then
		executable = executable .. ".exe"
	end

	local output = Output.create("C Build / Run", {
		"Source: " .. vim.fn.fnamemodify(file, ":~:."),
		"",
		"Compiling...",
	}, {
		filetype = "compiler",
		wrap = false,
	})

	local function show_compile_error(message, compiler_output)
		if not output.is_open() then
			return
		end

		output.append("\n" .. message .. "\n")
		if compiler_output ~= "" then
			output.append(compiler_output .. "\n")
		end
		output.set_title("C Build / Run · failed")
	end

	vim.system({
		clang,
		"-std=c23",
		"-g",
		"-O0",
		"-o",
		executable,
		file,
	}, {
		cwd = directory,
		text = true,
	}, function(result)
		vim.schedule(function()
			if not output.is_open() then
				return
			end

			local compiler_output = vim.trim(table.concat({
				result.stdout or "",
				result.stderr or "",
			}, "\n"))

			if result.code ~= 0 then
				show_compile_error(("Compilation failed (exit %d)"):format(result.code), compiler_output)
				return
			end

			output.set_title("C Build / Run · running")

			local _, terminal_error = output.open_terminal({ executable }, {
				cwd = directory,
			})

			if terminal_error then
				show_compile_error("Could not start program terminal:", terminal_error)
			end
		end)
	end)
end

keymap("n", "<leader>X", compile_and_run_c, OPTS("Compile and run C file"))

keymap("n", "<leader>u", function()
	vim.cmd.packadd("nvim.undotree")
	require("undotree").open()
end, { desc = "Undotree" })

keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
