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
require("soul.core.helpers.ui")
require("soul.core.neovide")

GET("soul.plugins.alpha")
GET("soul.plugins.breadcrumbs")
GET("soul.plugins.devicons")
GET("soul.plugins.gitsigns")
GET("soul.plugins.lualine")
GET("soul.plugins.mini")
GET("soul.plugins.render_md")
GET("soul.plugins.telescope")
GET("soul.plugins.yap")
GET("soul.plugins.toggleterm")
GET("soul.plugins.treesitter")
GET("soul.plugins.undotree")
GET("soul.plugins.whichkey")

GET("soul.lsp.lsp")
GET("soul.lsp.dap")
GET("soul.cmp.blink")

GET("soul.extras.colorizer")
GET("soul.extras.everforest")
GET("soul.extras.eyeliner")
GET("soul.extras.tiny_cmdline")
GET("soul.extras.todo")
GET("soul.extras.ufo")

require("soul.lazy")
