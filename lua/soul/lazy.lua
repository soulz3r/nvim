local OPTS = require("soul.core.helpers.keymaps").opts
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

local lazy_entry = lazypath .. "/lua/lazy/init.lua"

if not vim.uv.fs_stat(lazy_entry) then
	if vim.uv.fs_stat(lazypath) then
		error(
			"lazy.nvim exists but is incomplete: "
				.. lazypath
				.. "\\nRemove that directory and restart Neovim to bootstrap a clean copy."
		)
	end

	local ok, process = pcall(vim.system, {
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	}, {
		text = true,
	})

	if not ok then
		error("Failed to start lazy.nvim bootstrap: " .. tostring(process))
	end

	local result = process:wait(120000)
	if not result then
		pcall(function()
			process:kill(9)
		end)
		error("Timed out while cloning lazy.nvim after 120 seconds.")
	end

	if result.code ~= 0 then
		local output = (result.stderr and result.stderr ~= "" and result.stderr) or result.stdout
		error("Failed to bootstrap lazy.nvim:\\n" .. (output or "Unknown git error"))
	end

	if not vim.uv.fs_stat(lazy_entry) then
		error("lazy.nvim clone completed, but lua/lazy/init.lua is missing: " .. lazypath)
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
