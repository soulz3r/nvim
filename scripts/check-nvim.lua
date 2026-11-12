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
local platform = require("soul.core.platform")
local original_pwsh = vim.env.PWSH

if platform.is_windows then
	vim.env.PWSH = "pwsh"
end

local resolved_paths = require("soul.core.helpers.paths")

if platform.is_windows and vim.fn.exepath("pwsh") ~= "" then
	assert(resolved_paths.pwsh ~= "pwsh", "PWSH=pwsh must resolve to a concrete Windows executable path")
end

vim.env.PWSH = original_pwsh

require("soul.core.options")
require("soul.core.keymaps")
local keymap_helpers = require("soul.core.helpers.keymaps")
local lsp_config = require("soul.lsp.lsp")
for _, server in ipairs(lsp_config.servers) do
	assert(
		vim.fn.filereadable(root .. "/lsp/" .. server .. ".lua") == 1,
		("Enabled LSP '%s' has no matching lsp/%s.lua config"):format(server, server)
	)
end

local dap_args = require("soul.core.helpers.dap.args")
local argument_cases = {
	{},
	{ "" },
	{ "simple", "two words", "it's", 'a\\"b' },
	{ "single'quote", "quote\\\"and'quote", "trailing\\" },
	{ "C:\\Program Files\\app\\", "--name", "value with spaces" },
}

for _, is_windows in ipairs({ false, true }) do
	for _, expected in ipairs(argument_cases) do
		local encoded = dap_args.format(expected)
		local decoded, parse_error = dap_args.parse(encoded, is_windows)
		assert(decoded, tostring(parse_error))
		assert(vim.deep_equal(decoded, expected), "DAP argument round-trip failed: " .. encoded)
	end
end

local malformed, malformed_error = dap_args.parse('"unterminated', false)
assert(malformed == nil and malformed_error, "DAP argument parser must reject unclosed quotes")

local animation = require("soul.core.helpers.dashboard.animation").new({
	interval = 1,
	is_active = function()
		return true
	end,
	on_tick = function()
		error("expected animation callback failure")
	end,
})
animation.start()
assert(
	vim.wait(100, function()
		return not animation.is_running()
	end, 1),
	"Dashboard animation must stop cleanly after a callback error"
)

local dashboard_buttons = require("soul.core.helpers.dashboard.buttons").items
local buttons_by_key = {}
for _, item in ipairs(dashboard_buttons) do
	buttons_by_key[item.key] = item
end
local icon_registry = require("soul.core.helpers.icons")
for _, item in ipairs(dashboard_buttons) do
	assert(
		icon_registry[item.icon_group] and icon_registry[item.icon_group][item.icon],
		("Dashboard button '%s' references a missing icon: %s.%s"):format(item.key, item.icon_group, item.icon)
	)
end

assert(
	buttons_by_key.e.command:find("require('lazy').load", 1, true),
	"Dashboard Explorer button must load lazy Mini Files before requiring it"
)
assert(
	buttons_by_key.c.command == "<cmd>edit " .. vim.fn.fnameescape(vim.fn.stdpath("config") .. "/init.lua") .. "<CR>",
	"Dashboard Config button must escape config paths"
)

assert(type(keymap_helpers.opts) == "function", "shared keymap options helper is missing")
assert(rawget(_G, "OPTS") == nil, "OPTS must not leak into the global namespace")

local lua_ls = require("lsp.lua_ls")
local lua_globals = lua_ls.settings.Lua.diagnostics.globals
assert(not vim.tbl_contains(lua_globals, "OPTS"), "LuaLS must not declare OPTS as a global")
require("soul.core.autocmds")
assert(#vim.api.nvim_get_autocmds({ group = "SoulCore" }) > 0, "core autocmd group was not registered")

-- Re-sourcing the autocmd module while a qualifying float is open must not
-- lose the original global statusline setting.
local original_laststatus = vim.o.laststatus
vim.o.laststatus = 2
local float_buf = vim.api.nvim_create_buf(false, true)
vim.bo[float_buf].modifiable = false
local float_win = vim.api.nvim_open_win(float_buf, true, {
	relative = "editor",
	width = 1,
	height = 1,
	row = 0,
	col = 0,
	style = "minimal",
})
assert(
	vim.wait(100, function()
		return vim.o.laststatus == 0
	end, 10),
	"float did not hide the global statusline"
)
dofile(root .. "/lua/soul/core/autocmds.lua")
vim.api.nvim_win_close(float_win, true)
assert(
	vim.wait(100, function()
		return vim.o.laststatus == 2
	end, 10),
	"reloading autocmds lost the original statusline setting"
)
vim.o.laststatus = original_laststatus
local alpha_autocmds = require("soul.core.helpers.dashboard.alpha.autocmds")
local alpha_state = {
	animation = {
		start = function() end,
		stop = function() end,
	},
	footer = {
		invalidate = function() end,
		update = function() end,
	},
}
alpha_autocmds.register(alpha_state)
local alpha_autocmd_count = #vim.api.nvim_get_autocmds({ group = "SoulAlpha" })
assert(alpha_autocmd_count > 0, "Alpha autocmd group was not registered")
alpha_autocmds.register(alpha_state)
assert(
	#vim.api.nvim_get_autocmds({ group = "SoulAlpha" }) == alpha_autocmd_count,
	"Alpha autocmd registration must be idempotent"
)

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

local telescope_spec = require("soul.plugins.telescope")
local fzf_spec

for _, dependency in ipairs(telescope_spec.dependencies or {}) do
	if type(dependency) == "table" and dependency[1] == "nvim-telescope/telescope-fzf-native.nvim" then
		fzf_spec = dependency
		break
	end
end

assert(fzf_spec and type(fzf_spec.build) == "function", "Telescope fzf-native needs a platform-aware build function")

local yap_spec = require("soul.plugins.yap")
assert(
	vim.tbl_contains(yap_spec.dependencies or {}, "nvim-telescope/telescope-project.nvim"),
	"YAP must declare the Telescope project extension"
)

local undotree_spec = require("soul.plugins.undotree")
assert(undotree_spec[1] == "jiaoshijie/undotree", "Undotree plugin repository is incorrect")
assert(type(undotree_spec.keys) == "table", "Undotree must be lazy-loaded from its keymap")

local lockfile = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
assert(lockfile.undotree, "Undotree is missing from lazy-lock.json")
assert(
	type(lockfile.undotree.commit) == "string"
		and #lockfile.undotree.commit == 40
		and lockfile.undotree.commit:match("^[0-9a-f]+$"),
	"Undotree lock revision must be a full commit SHA"
)

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
