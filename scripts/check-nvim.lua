local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

assert(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")
assert(vim.uv, "vim.uv is required")
assert(type(vim.system) == "function", "vim.system is required")
assert(type(vim.keymap.set) == "function", "vim.keymap.set is required")
assert(type(vim.lsp.enable) == "function", "vim.lsp.enable is required")
assert(vim.o.winborder ~= nil, "'winborder' option is required")

require("soul.launch")
require("soul.core.platform")
require("soul.core.helpers.paths")
require("soul.core.options")
require("soul.core.keymaps")
local keymap_helpers = require("soul.core.helpers.keymaps")
assert(type(keymap_helpers.opts) == "function", "shared keymap options helper is missing")
assert(rawget(_G, "OPTS") == nil, "OPTS must not leak into the global namespace")

local lua_ls = require("lsp.lua_ls")
local lua_globals = lua_ls.settings.Lua.diagnostics.globals
assert(not vim.tbl_contains(lua_globals, "OPTS"), "LuaLS must not declare OPTS as a global")
require("soul.core.autocmds")
assert(#vim.api.nvim_get_autocmds({ group = "SoulCore" }) > 0, "core autocmd group was not registered")
require("soul.core.helpers.ui")
require("soul.core.helpers.ui.output")
require("soul.core.neovide")

local modules = {
	"soul.plugins.alpha",
	"soul.plugins.breadcrumbs",
	"soul.plugins.devicons",
	"soul.plugins.gitsigns",
	"soul.plugins.lualine",
	"soul.plugins.mini",
	"soul.plugins.render_md",
	"soul.plugins.telescope",
	"soul.plugins.yap",
	"soul.plugins.toggleterm",
	"soul.plugins.treesitter",
	"soul.plugins.undotree",
	"soul.plugins.whichkey",
	"soul.lsp.lsp",
	"soul.lsp.dap",
	"soul.cmp.blink",
	"soul.extras.colorizer",
	"soul.extras.everforest",
	"soul.extras.eyeliner",
	"soul.extras.tiny_cmdline",
	"soul.extras.todo",
	"soul.extras.ufo",
}

for _, name in ipairs(modules) do
	local ok, spec = pcall(require, name)
	assert(ok, name .. ": " .. tostring(spec))
	assert(type(spec) == "table", name .. " did not return a plugin spec table")
end

local undotree_spec = require("soul.plugins.undotree")
assert(undotree_spec[1] == "jiaoshijie/undotree", "Undotree plugin repository is incorrect")
assert(type(undotree_spec.keys) == "table", "Undotree must be lazy-loaded from its keymap")

local lockfile = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\\n"))
assert(lockfile.undotree, "Undotree is missing from lazy-lock.json")
assert(lockfile.undotree.commit == "ae312c61558ee41316e992d3bae3afea2a77f62c", "Undotree lock revision is stale")

local mini_specs = require("soul.plugins.mini")
local mini_files_spec

for _, spec in ipairs(mini_specs) do
	if spec[1] == "nvim-mini/mini.files" then
		mini_files_spec = spec
		break
	end
end

assert(mini_files_spec, "Mini Files plugin specification is missing")
assert(not vim.uv.fs_stat("lua/soul/plugins/oil.lua"), "Unused Oil plugin specification should not be present")
assert(
	vim.tbl_contains(mini_files_spec.dependencies or {}, "nvim-mini/mini.icons"),
	"Mini Files must load Mini Icons as a dependency"
)

print("Neovim core and plugin-spec smoke tests passed.")
