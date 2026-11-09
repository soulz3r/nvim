vim.opt.backup = false
vim.opt.cmdheight = 1
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.conceallevel = 0
-- vim.opt.fileencoding = "utf-8" -- the encoding written to a file
vim.opt.hlsearch = true
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
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.timeoutlen = 1000
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
vim.opt.scrolloff = 0
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

vim.opt.winborder = "rounded"

vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])

vim.g.netrw_banner = 0
vim.g.netrw_mouse = 2

vim.opt.clipboard = "unnamedplus"

if vim.fn.has("wsl") == 1 then
	vim.g.clipboard = {
		name = "WslClipboard",
		copy = {
			["+"] = "clip.exe",
			["*"] = "clip.exe",
		},
		paste = {
			["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
			["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
		},
		cache_enabled = 0,
	}
end

local paths = require("soul.core.paths")
if paths.is_windows then
	vim.opt.shell = paths.pwsh
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""
end

if vim.g.neovide then
    vim.g.neovide_theme = "dark"
    vim.g.neovide_corner_preference = "round"
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_confirm_quit = true

    vim.g.neovide_title_background_color = "#2D353B"
    vim.g.neovide_title_text_color = "#D3C6AA"


    vim.g.neovide_padding_top = 8
    vim.g.neovide_padding_bottom = 8
    vim.g.neovide_padding_left = 4
    vim.g.neovide_padding_right = 4

    vim.g.neovide_opacity = 0.97
    vim.g.neovide_normal_opacity = 1.0

    vim.g.neovide_floating_blur_amount_x = 2.5
    vim.g.neovide_floating_blur_amount_y = 2.5

    vim.g.neovide_floating_shadow = true
    vim.g.neovide_floating_z_height = 12
    vim.g.neovide_light_angle_degrees = 45
    vim.g.neovide_light_radius = 5

    vim.g.neovide_floating_corner_radius = 0.25

    vim.g.neovide_cursor_animation_length = 0.13
    vim.g.neovide_cursor_short_animation_length = 0.04
    vim.g.neovide_cursor_trail_size = 0.35

    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.g.neovide_cursor_animate_command_line = true
    vim.g.neovide_cursor_antialiasing = true

    vim.g.neovide_cursor_vfx_mode = ""


    vim.g.neovide_scroll_animation_length = 0.18
    vim.g.neovide_position_animation_length = 0.12
    vim.g.neovide_scroll_animation_far_lines = 1

    vim.g.neovide_refresh_rate = 75
    vim.g.neovide_refresh_rate_idle = 5


    vim.opt.guifont = "ComicShannsMono Nerd Font:h10"
end

