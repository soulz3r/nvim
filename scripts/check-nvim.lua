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
local platform_module = "soul.core.platform"
local platform = require(platform_module)

-- Exercise Linux-hosted WSL and Termux detection without requiring those
-- environments to be installed on the CI runner.
if platform.is_linux then
	local original_wsl_name = vim.env.WSL_DISTRO_NAME
	local original_prefix = vim.env.PREFIX

	vim.env.WSL_DISTRO_NAME = "nvim-ci-wsl"
	package.loaded[platform_module] = nil
	local simulated_wsl = require(platform_module)
	assert(simulated_wsl.is_wsl and not simulated_wsl.is_linux, "WSL environment detection failed")

	vim.env.WSL_DISTRO_NAME = original_wsl_name
	vim.env.PREFIX = "/data/data/com.termux/files/usr"
	package.loaded[platform_module] = nil
	local simulated_termux = require(platform_module)
	assert(simulated_termux.is_termux and not simulated_termux.is_linux, "Termux environment detection failed")

	vim.env.PREFIX = original_prefix
	package.loaded[platform_module] = platform
end

local paths_module = "soul.core.helpers.paths"
local original_pwsh = vim.env.PWSH
local original_paths = package.loaded[paths_module]
local pwsh_on_path = platform.is_windows and vim.fn.exepath("pwsh") ~= ""

-- Exercise PowerShell discovery from a clean module state. This keeps the
-- test valid even if another smoke test starts importing paths.lua earlier.
if platform.is_windows then
	vim.env.PWSH = "pwsh"
	package.loaded[paths_module] = nil
end

local pwsh_started = vim.uv.hrtime()
local resolved_paths = require(paths_module)
local configured_projects_dir = vim.env.PROJECTS_DIR and vim.trim(vim.env.PROJECTS_DIR) or ""
local expected_projects_dir = configured_projects_dir ~= "" and configured_projects_dir or vim.fn.expand("~/projects")
assert(
	resolved_paths.projects == expected_projects_dir,
	"Project directory must honor PROJECTS_DIR and otherwise default to ~/projects"
)
local pwsh_elapsed_ms = (vim.uv.hrtime() - pwsh_started) / 1e6

if vim.env.PROFILE_PWSH == "1" then
	print(("PowerShell resolver completed in %.2f ms (%s)"):format(pwsh_elapsed_ms, tostring(resolved_paths.pwsh)))
end

if platform.is_windows and (vim.env.REQUIRE_PWSH == "1" or pwsh_on_path) then
	assert(
		type(resolved_paths.pwsh) == "string" and resolved_paths.pwsh ~= "" and resolved_paths.pwsh ~= "pwsh",
		"PowerShell 7 must resolve to a concrete Windows executable path"
	)
	assert(
		vim.fn.executable(resolved_paths.pwsh) == 1,
		"PWSH resolver returned a path that is not executable: " .. tostring(resolved_paths.pwsh)
	)

	-- Invalid inherited environment hints must not prevent PATH discovery.
	local original_pshome = vim.env.PSHOME
	vim.env.PWSH = "C:/nvim-ci/missing/PowerShell/pwsh.exe"
	vim.env.PSHOME = "C:/nvim-ci/missing/PowerShell"
	package.loaded[paths_module] = nil
	local invalid_hints = require(paths_module)
	assert(
		invalid_hints.pwsh ~= "pwsh" and vim.fn.executable(invalid_hints.pwsh) == 1,
		"Invalid PWSH and PSHOME hints must fall back to a valid PowerShell 7 on PATH"
	)

	-- Windows PowerShell 5.1 may be present beside PowerShell 7, but must never
	-- win merely because it was explicitly supplied through PWSH.
	local windows_powershell = vim.fn.exepath("powershell.exe")
	if windows_powershell ~= "" then
		vim.env.PWSH = windows_powershell
		vim.env.PSHOME = "C:/nvim-ci/missing/PowerShell"
		package.loaded[paths_module] = nil
		local rejects_legacy = require(paths_module)
		assert(
			rejects_legacy.pwsh ~= windows_powershell,
			"Windows PowerShell 5.1 must not be selected as the configured shell"
		)
	end

	vim.env.PWSH = resolved_paths.pwsh
	vim.env.PSHOME = resolved_paths.pwsh:gsub("[/\\\\]pwsh%.exe$", "")
	package.loaded[paths_module] = nil
	local path_with_spaces = require(paths_module)
	assert(
		path_with_spaces.pwsh == resolved_paths.pwsh,
		"PowerShell discovery must preserve and execute paths containing spaces"
	)
	vim.env.PSHOME = original_pshome
end

vim.env.PWSH = original_pwsh
package.loaded[paths_module] = original_paths

require("soul.core.options")
require("soul.core.keymaps")
local keymap_helpers = require("soul.core.helpers.keymaps")
local lsp_servers = require("soul.lsp.servers")
for _, server in ipairs(lsp_servers) do
	assert(
		vim.fn.filereadable(root .. "/lsp/" .. server .. ".lua") == 1,
		("Enabled LSP '%s' has no matching lsp/%s.lua config"):format(server, server)
	)
end

-- Load two real server definitions through Neovim's native LSP config API.
-- This catches malformed server modules and config-registration regressions
-- without requiring clangd or lua-language-server binaries on the CI runner.
for _, server in ipairs({ "clangd", "lua_ls" }) do
	local config = require("lsp." .. server)
	assert(type(config) == "table", server .. " did not return an LSP config")
	vim.lsp.config(server, config)
	vim.lsp.enable(server)
	assert(type(vim.lsp.config[server]) == "table", server .. " was not registered with vim.lsp.config")
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

local process_helper = require("soul.core.helpers.process")
local completed_124 = process_helper.wait({
	wait = function()
		return { code = 124, stdout = "", stderr = "" }
	end,
}, 100)
assert(
	completed_124 and completed_124.code == 124,
	"A completed process exit code of 124 must not be treated as a timeout"
)

local timeout_waits = 0
local timeout_killed = false
local timed_out, timeout_error = process_helper.wait({
	wait = function()
		timeout_waits = timeout_waits + 1
		if timeout_waits == 1 then
			return nil
		end
		return { code = 137 }
	end,
	kill = function(_, signal)
		timeout_killed = signal == 9
	end,
}, 25)
assert(timed_out == nil and timeout_error, "A timed-out process must return a useful error")
assert(timeout_killed and timeout_waits == 2, "A timed-out process must be killed and reaped")

local failed_waits = 0
local failed_wait_killed = false
local failed_wait = process_helper.wait({
	wait = function()
		failed_waits = failed_waits + 1
		if failed_waits == 1 then
			error("simulated wait failure")
		end
		return { code = 137 }
	end,
	kill = function(_, signal)
		failed_wait_killed = signal == 9
	end,
}, 25)
assert(failed_wait == nil, "A failed process wait must not report a result")
assert(failed_wait_killed and failed_waits == 2, "A failed process wait must clean up the child")

local original_notify = vim.notify
local animation_notifications = {}
vim.notify = function(message, level, opts)
	animation_notifications[#animation_notifications + 1] = {
		message = tostring(message),
		level = level,
		title = opts and opts.title,
	}
end

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
local animation_stopped = vim.wait(100, function()
	return not animation.is_running()
end, 1)
vim.notify = original_notify

assert(animation_stopped, "Dashboard animation must stop cleanly after a callback error")
assert(
	#animation_notifications == 1
		and animation_notifications[1].message:find("Animation stopped:", 1, true)
		and animation_notifications[1].title == "Dashboard",
	"Dashboard animation must report callback failures through a warning notification"
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

local dap_spec = require("soul.lsp.dap")
assert(
	not vim.tbl_contains(dap_spec.dependencies or {}, "soulz3r/yap.nvim"),
	"DAP must not depend on YAP"
)

local lualine_spec = require("soul.plugins.lualine")
assert(
	not vim.tbl_contains(lualine_spec.dependencies or {}, "soulz3r/yap.nvim"),
	"Lualine's YAP project label must remain optional"
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
