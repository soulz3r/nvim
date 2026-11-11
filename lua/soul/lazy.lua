local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local ok, result = pcall(function()
		return vim.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath,
		}, {
			text = true,
		}):wait()
	end)

	if not ok then
		error("Failed to bootstrap lazy.nvim: " .. tostring(result))
	end

	if result.code ~= 0 then
		local output = (result.stderr and result.stderr ~= "" and result.stderr) or result.stdout
		error("Failed to bootstrap lazy.nvim:\n" .. (output or "Unknown git error"))
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = LAZY_PLUGIN_GET,
	git = {
		timeout = 600,
	},
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

vim.keymap.set("n", "<leader>L", "<cmd>Lazy<cr>", OPTS("Lazy"))
