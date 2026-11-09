local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = LAZY_PLUGIN_GET,
	rocks = {
		enabled = false,
		hererocks = false,
	},
	install = {
		colorscheme = { "darkplus", "everforest", "catppuccin", "default" },
	},
	ui = {
		border = "rounded",
	},
	change_detection = {
		enabled = true,
		notify = false,
	},
})

keymap("n", "<leader>L", "<cmd>Lazy<cr>", OPTS("Lazy"))
