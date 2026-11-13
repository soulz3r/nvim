-- Resolve the config root from this file itself. Do not depend on the
-- caller's working directory or environment-variable path conversion.
local source = debug.getinfo(1, "S").source
local config_root = vim.fn.fnamemodify(source:sub(2), ":p:h")
local lua_root = vim.fs.joinpath(config_root, "lua")

vim.opt.rtp:prepend(config_root)

-- Keep Lua module resolution explicit during early startup. This also covers
-- launchers that provide -u with a path outside the initial runtimepath.
package.path = table.concat({
	vim.fs.joinpath(lua_root, "?.lua"),
	vim.fs.joinpath(lua_root, "?", "init.lua"),
	package.path,
}, ";")

-- Experimental benchmark switch: cache compiled Lua modules without changing
-- normal startup unless explicitly requested by the user.
if vim.env.CVIM_LUA_LOADER == "1" then
	vim.loader.enable()
end

vim.g.cvim_start_ns = vim.uv.hrtime()

-- Set leaders before Lazy or any plugin can define leader mappings.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

if vim.fn.has("nvim-0.12") ~= 1 then
	error("soulz3r/nvim requires Neovim 0.12 or newer")
end

require("soul.launch")
require("soul.core.helpers.paths")
require("soul.core.options")
require("soul.core.autocmds")

-- Register core mappings after the first startup screen is ready. The
-- scheduled callback runs before Neovim begins processing user input.
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			require("soul.core.keymaps")
			vim.g.cvim_keymaps_ready = true
		end)
	end,
})
-- Defer project-history parsing until the startup UI is already available.
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		if vim.fn.argc() ~= 0 then
			return
		end

		vim.schedule(function()
			require("soul.core.lifecycle.project").restore()
		end)
	end,
})
require("soul.core.neovide")

-- Load spec modules directly and pass their returned tables to Lazy.
-- This avoids Lazy's directory discovery and loadfile-based import pass.
GET("soul.plugins.alpha")
GET("soul.plugins.breadcrumbs")
GET("soul.plugins.devicons")
GET("soul.plugins.gitsigns")
GET("soul.plugins.lualine")
GET("soul.plugins.mini")
GET("soul.plugins.render_md")
GET("soul.plugins.telescope")
GET("soul.plugins.toggleterm")
GET("soul.plugins.treesitter")
GET("soul.plugins.undotree")
GET("soul.plugins.whichkey")
GET("soul.plugins.yap")

GET("soul.extras.colorizer")
GET("soul.extras.everforest")
GET("soul.extras.eyeliner")
GET("soul.extras.tiny_cmdline")
GET("soul.extras.todo")
GET("soul.extras.ufo")

GET("soul.lsp.lsp")
GET("soul.lsp.dap")
GET("soul.cmp.blink")

require("soul.lazy")

-- Apply CVIM highlights after Everforest has set the base colorscheme.
require("soul.core.helpers.ui")

-- Used by the repository benchmark to verify this checkout actually loaded.
vim.g.cvim_config_loaded = true
