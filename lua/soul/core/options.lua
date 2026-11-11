vim.opt.backup = false
vim.opt.cmdheight = 0
vim.opt.report = 9999
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.conceallevel = 0
-- vim.opt.fileencoding = "utf-8" -- the encoding written to a file
vim.opt.hlsearch = true
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.mouse = "a"
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.showmode = false
vim.opt.showtabline = 0
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "screen"
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.timeoutlen = 500
vim.opt.undofile = true
vim.opt.updatetime = 100
vim.opt.writebackup = false

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 2
vim.opt.signcolumn = "yes"

vim.opt.laststatus = 3

vim.opt.showcmd = false
vim.opt.ruler = false

vim.opt.wrap = false
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- vim.opt.guifont = "FiraCode Nerd Font:h10"
-- vim.opt.guifont = "MonaspiceRn Nerd Font:h9"
vim.opt.guifont = "ComicShannsMono Nerd Font:h9"

vim.opt.title = false

-- colorcolumn = "80",
-- colorcolumn = "120",

vim.opt.fillchars = vim.opt.fillchars + "eob: "

vim.opt.fillchars:append({
	stl = " ",
})

vim.opt.shortmess:append("c")

vim.opt.winborder = require("soul.core.helpers.ui.floats").style

vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])

vim.g.netrw_banner = 0
vim.g.netrw_mouse = 2

vim.opt.clipboard = "unnamedplus"

local platform = require("soul.core.platform")
local paths = require("soul.core.helpers.paths")

if platform.is_wsl and paths.wsl_clipboard then
	local copy_command = vim.fn.shellescape(paths.wsl_clipboard.copy)
	local paste_command = vim.fn.shellescape(paths.wsl_clipboard.paste)
		.. " -NoLogo -NoProfile -Command "
		.. vim.fn.shellescape('[Console]::Out.Write((Get-Clipboard -Raw).Replace("`r", ""))')

	vim.g.clipboard = {
		name = "WslClipboard",
		copy = {
			["+"] = copy_command,
			["*"] = copy_command,
		},
		paste = {
			["+"] = paste_command,
			["*"] = paste_command,
		},
		cache_enabled = 0,
	}
end

if platform.is_windows then
	vim.opt.shell = paths.pwsh
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""
end

