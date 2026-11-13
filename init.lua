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

vim.g.cvim_start_ns = vim.uv.hrtime()

if vim.fn.has("nvim-0.12") ~= 1 then
	error("soulz3r/nvim requires Neovim 0.12 or newer")
end

require("soul.launch")
require("soul.core.helpers.paths")
require("soul.core.options")
require("soul.core.keymaps")
require("soul.core.autocmds")
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

-- Import each plugin-spec directory once instead of rescanning it for
-- every individual file.
GET("soul.plugins")
GET("soul.extras")

-- These directories also contain non-spec modules, so keep their imports
-- explicit rather than importing the entire directory.
GET("soul.lsp.lsp")
GET("soul.lsp.dap")
GET("soul.cmp.blink")

require("soul.lazy")

-- Apply CVIM highlights after Everforest has set the base colorscheme.
require("soul.core.helpers.ui")

-- Used by the repository benchmark to verify this checkout actually loaded.
vim.g.cvim_config_loaded = true
