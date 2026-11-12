local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

assert(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")
require("soul.launch")

local notifications = {}
local original_notify = vim.notify
vim.notify = function(message, level, opts)
	notifications[#notifications + 1] = {
		message = tostring(message),
		level = level,
		title = opts and opts.title,
	}
end

local registry_state = {}
local registry = {
	list = function()
		return {}
	end,
	get = function(root)
		return registry_state[root]
	end,
	update = function(root, fields)
		local entry = registry_state[root] or { root = root }
		for key, value in pairs(fields) do
			entry[key] = value
		end
		registry_state[root] = entry
		return true
	end,
	touch = function()
		return true
	end,
}

local dap = {
	adapters = {},
	configurations = {},
	defaults = { fallback = {} },
	listeners = {
		before = { event_initialized = {} },
		after = {
			event_exited = {},
			event_terminated = {},
		},
	},
	repl = {
		open = function() end,
	},
	session = function()
		return nil
	end,
	continue = function() end,
	launch_count = 0,
}

function dap.run(config)
	dap.last_config = config
	dap.launch_count = dap.launch_count + 1
end

local dapui = {
	elements = {
		watches = {
			add = function() end,
		},
	},
	setup = function() end,
	open_count = 0,
	toggle_count = 0,
}

function dapui.open()
	dapui.open_count = dapui.open_count + 1
end

function dapui.toggle()
	dapui.toggle_count = dapui.toggle_count + 1
end

function dapui.float_element() end

package.preload["soul.core.helpers.dap.project.registry"] = function()
	return {
		setup = function()
			return registry
		end,
	}
end
package.preload["soul.core.helpers.dap.registry"] = function()
	return {
		import_yap_file = function()
			return true
		end,
		migrate_file = function()
			return true
		end,
	}
end
package.preload["dap"] = function()
	return dap
end
package.preload["dapui"] = function()
	return dapui
end
package.preload["dap.ui.widgets"] = function()
	return {
		hover = function() end,
	}
end

local dap_spec = require("soul.lsp.dap")
assert(type(dap_spec.config) == "function", "DAP plugin config callback is missing")
dap_spec.config()
assert(package.loaded["yap.project_registry"] == nil, "DAP must not load YAP's project registry")

local paths = require("soul.core.helpers.paths")
assert(dap.adapters.lldb, "LLDB adapter was not configured")
assert(dap.adapters.lldb.type == "executable", "LLDB must use an executable adapter")
assert(dap.adapters.lldb.command == paths.lldb_dap, "LLDB adapter did not use the resolved executable")
assert(dap.configurations.c and #dap.configurations.c == 2, "C launch configurations were not registered")
assert(dap.configurations.cpp == dap.configurations.c, "C++ should reuse the C launch configurations")
assert(dap.configurations.rust == dap.configurations.c, "Rust should reuse the C launch configurations")
assert(dap.defaults.fallback.switchbuf == "useopen", "DAP must not open unrelated source buffers")

local function find_mapping(description)
	for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do
		if mapping.desc == description then
			return mapping
		end
	end
end

-- Exercise the real DAP launch callback against a stateful in-memory registry.
-- The test uses Neovim's own executable so it does not depend on a compiler.
local project_root = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.getcwd()), ":p"):gsub("\\", "/")
if project_root ~= "/" and not project_root:match("^%a:/$") then
	project_root = project_root:gsub("/+$", "")
end

local test_executable = vim.fn.fnamemodify(vim.fn.resolve(vim.v.progpath), ":p")
assert(vim.fn.executable(test_executable) == 1, "Neovim test executable must be runnable")
registry_state[project_root] = {
	root = project_root,
	dap_enabled = true,
	executable = test_executable,
	args = { "--previous" },
}

local start_mapping = find_mapping("DAP: Start / continue with arguments")
assert(start_mapping and type(start_mapping.callback) == "function", "DAP start mapping is missing")
local original_input = vim.ui.input
vim.ui.input = function(opts, callback)
	assert(opts.prompt == "Program arguments: ", "DAP launch must prompt for program arguments")
	callback('--name "two words"')
end
start_mapping.callback()
vim.ui.input = original_input

assert(dap.last_config, "DAP start mapping did not launch the configured executable")
assert(dap.last_config.program == test_executable, "DAP launch used the wrong project executable")
assert(vim.deep_equal(dap.last_config.args, { "--name", "two words" }), "DAP launch arguments were parsed incorrectly")
assert(
	vim.deep_equal(registry_state[project_root].args, { "--name", "two words" }),
	"DAP launch arguments were not persisted to its independent project registry"
)

local launch_count = dap.launch_count
vim.ui.input = function(_, callback)
	callback(nil)
end
start_mapping.callback()
vim.ui.input = original_input
assert(dap.launch_count == launch_count, "Cancelling the DAP argument prompt must not launch a session")

local toggle_mapping = find_mapping("DAP UI: Toggle")
assert(toggle_mapping and type(toggle_mapping.callback) == "function", "DAP UI toggle mapping is missing")
toggle_mapping.callback()
assert(dapui.toggle_count == 1, "DAP UI toggle mapping did not call dapui.toggle")

local project_mapping = find_mapping("DAP: Select saved project")
assert(project_mapping and type(project_mapping.callback) == "function", "DAP project mapping is missing")
project_mapping.callback()
assert(
	notifications[#notifications] and notifications[#notifications].message:find("No saved DAP projects", 1, true),
	"Selecting an empty project registry must report that no projects are saved"
)

local terminate_mapping = find_mapping("DAP: Kill session")
assert(terminate_mapping and type(terminate_mapping.callback) == "function", "DAP terminate mapping is missing")
terminate_mapping.callback()
assert(
	notifications[#notifications] and notifications[#notifications].message:find("No active debug session", 1, true),
	"Terminating without a session must report a useful warning"
)

local initialized = dap.listeners.before.event_initialized.soul_dap_source
assert(type(initialized) == "function", "DAP initialized listener was not registered")
initialized()
assert(dapui.open_count == 1, "DAP UI must open when a debug session initializes")

local exited = dap.listeners.after.event_exited.soul_dap_source
assert(type(exited) == "function", "DAP exit listener was not registered")

local source_win = vim.api.nvim_get_current_win()
local source_buf = vim.api.nvim_get_current_buf()
local other_buf = vim.api.nvim_create_buf(false, true)
local other_win = vim.api.nvim_open_win(other_buf, true, {
	relative = "editor",
	width = 10,
	height = 2,
	row = 0,
	col = 0,
	style = "minimal",
})

exited()
assert(
	vim.wait(100, function()
		return vim.api.nvim_get_current_win() == source_win
	end, 10),
	"DAP exit must restore the original source window"
)
assert(vim.api.nvim_win_get_buf(source_win) == source_buf, "DAP exit must restore the original source buffer")
vim.api.nvim_win_close(other_win, true)

-- Closing the original source window during a session must not make teardown
-- attempt to restore an invalid window.
local fallback_win = vim.api.nvim_get_current_win()
local temporary_buf = vim.api.nvim_create_buf(false, true)
local temporary_win = vim.api.nvim_open_win(temporary_buf, true, {
	relative = "editor",
	width = 10,
	height = 2,
	row = 0,
	col = 0,
	style = "minimal",
})
initialized()
vim.api.nvim_win_close(temporary_win, true)
assert(pcall(exited), "DAP teardown must tolerate a source window closed during the session")
assert(
	vim.wait(100, function()
		return vim.api.nvim_get_current_win() == fallback_win
	end, 10),
	"DAP teardown must leave focus in a valid window when the source window was closed"
)

local output = require("soul.core.helpers.ui.output")
local window = output.create("Integration test", { "first" })
window.append(" second\nthird")
local lines = vim.api.nvim_buf_get_lines(window.buf, 0, -1, false)
assert(vim.deep_equal(lines, { "first second", "third" }), "Floating output append did not preserve line boundaries")
assert(window.is_open(), "Floating output window did not open")
window.close()
assert(not window.is_open(), "Floating output window did not close")

vim.notify = original_notify
print("Neovim integration smoke tests passed.")
