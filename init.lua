require("soul.launch")
require("soul.core.options")
require("soul.core.keymaps")
require("soul.core.autocmds")
require("soul.core.pRunner")

GET("soul.plugins.devicons")
GET("soul.plugins.treesitter")
GET("soul.plugins.schemastore")
GET("soul.plugins.telescope")
GET("soul.plugins.illuminate")
GET("soul.plugins.whichkey")
GET("soul.plugins.navic")
GET("soul.plugins.breadcrumbs")
GET("soul.plugins.alpha")
GET("soul.plugins.project")
GET("soul.plugins.toggleterm")
GET("soul.plugins.render_md")
GET("soul.plugins.mini")
GET("soul.plugins.lualine")
GET("soul.plugins.gitsigns")

GET("soul.lsp.lsp")
GET("soul.lsp.dap")
GET("soul.cmp.blink")

GET("soul.extras.noice")
GET("soul.extras.eyeliner")
GET("soul.extras.ufo")
GET("soul.extras.todo")
GET("soul.extras.colorizer")
GET("soul.extras.everforest")
GET("soul.extras.modicator")
GET("soul.extras.navbuddy")

require("soul.lazy")
require("soul.core.colors")

if vim.fn.has("win32") == 1 then
	vim.cmd.cd("D:\\config\\projects")
elseif vim.fn.has("unix") == 1 then
	vim.cmd.cd("~/projects")
end
