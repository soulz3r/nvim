local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

local Scope = require("soul.core.lifecycle.scope")
local scope = Scope.new()
local cleaned = 0

scope:add(function()
	cleaned = cleaned + 1
end)

local timer = scope:timer()
timer:start(60000, 0, function() end)

local group = scope:augroup("SoulLifecycleScopeTest")
vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "SoulLifecycleScopeTest",
	callback = function() end,
})

assert(#vim.api.nvim_get_autocmds({ group = group }) == 1, "scope augroup was not created")
scope:close()
assert(scope:is_closed(), "scope did not enter the closed state")
assert(cleaned == 1, "scope cleanup did not run exactly once")
assert(timer:is_closing(), "scope did not close its timer")
assert(
	#vim.api.nvim_get_autocmds({ event = "User", pattern = "SoulLifecycleScopeTest" }) == 0,
	"scope did not delete its augroup"
)
scope:close()
assert(cleaned == 1, "closing a scope twice repeated cleanup")

-- Dashboard shortcuts must be real buffer-local mappings, and temporary
-- departures must pause rather than destroy the animation lifecycle.
local alpha_autocmds = require("soul.core.helpers.dashboard.alpha.autocmds")
local original_buffer = vim.api.nvim_get_current_buf()
local alpha_buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(alpha_buffer)

local alpha_starts = 0
local alpha_stops = 0
local alpha_closes = 0
local alpha_autocmd_state = {
	animation = {
		start = function()
			alpha_starts = alpha_starts + 1
		end,
		stop = function()
			alpha_stops = alpha_stops + 1
		end,
		close = function()
			alpha_closes = alpha_closes + 1
		end,
	},
	footer = {
		invalidate = function() end,
		update = function() end,
	},
}

vim.api.nvim_create_user_command("AlphaRedraw", function() end, {})
alpha_autocmds.register(alpha_autocmd_state)
vim.bo[alpha_buffer].filetype = "alpha"

local alpha_keymaps = vim.api.nvim_buf_get_keymap(alpha_buffer, "n")
local find_file_mapping
for _, mapping in ipairs(alpha_keymaps) do
	if mapping.lhs == "f" then
		find_file_mapping = mapping
		break
	end
end

assert(find_file_mapping, "Alpha dashboard did not register its visible find-file shortcut")
assert(
	find_file_mapping.rhs:find("Telescope find_files", 1, true),
	"Alpha find-file shortcut is not bound to its displayed action"
)

vim.api.nvim_exec_autocmds("BufLeave", {
	buffer = alpha_buffer,
	modeline = false,
})
assert(alpha_stops == 1, "leaving Alpha did not pause its animation")
assert(alpha_closes == 0, "leaving Alpha destroyed the animation instead of pausing it")

vim.api.nvim_exec_autocmds("BufEnter", {
	buffer = alpha_buffer,
	modeline = false,
})
assert(alpha_starts >= 2, "returning to Alpha did not resume its animation")

vim.api.nvim_exec_autocmds("BufWipeout", {
	buffer = alpha_buffer,
	modeline = false,
})
assert(alpha_closes == 1, "wiping the Alpha buffer did not close its animation")
vim.api.nvim_del_user_command("AlphaRedraw")
vim.api.nvim_buf_delete(alpha_buffer, { force = true })
if vim.api.nvim_buf_is_valid(original_buffer) then
	vim.api.nvim_set_current_buf(original_buffer)
end

local lifecycle = require("soul.core.lifecycle.lsp")
local original_timeout = lifecycle.idle_timeout
local original_get_client = vim.lsp.get_client_by_id
local original_stop_client = vim.lsp.stop_client
local clients = {}

vim.lsp.get_client_by_id = function(client_id)
	return clients[client_id] or original_get_client(client_id)
end

vim.lsp.stop_client = function(client_id, force)
	local client = clients[client_id]
	assert(client, "unexpected LSP client shutdown")
	assert(force == false, "idle LSP shutdown must be graceful")
	client.stopped = true
end

local function fake_client(client_id)
	local client = {
		id = client_id,
		attached_buffers = {},
		stopped = false,
	}

	function client:is_stopped()
		return self.stopped
	end

	clients[client_id] = client
	return client
end

lifecycle.idle_timeout = 30
lifecycle.setup()

local idle_client = fake_client(987601)
vim.api.nvim_exec_autocmds("LspDetach", {
	data = { client_id = idle_client.id },
	modeline = false,
})

assert(
	vim.wait(250, function()
		return idle_client.stopped
	end, 5),
	"an unattached LSP client was not stopped after its idle timeout"
)

local active_client = fake_client(987602)
vim.api.nvim_exec_autocmds("LspDetach", {
	data = { client_id = active_client.id },
	modeline = false,
})
vim.wait(10, function()
	return false
end, 1)

local buffer = vim.api.nvim_create_buf(false, true)
active_client.attached_buffers[buffer] = true
vim.api.nvim_exec_autocmds("LspAttach", {
	data = { client_id = active_client.id },
	modeline = false,
})
vim.wait(80, function()
	return false
end, 2)

assert(not active_client.stopped, "reattaching a buffer did not cancel idle shutdown")

lifecycle.idle_timeout = original_timeout
vim.lsp.get_client_by_id = original_get_client
vim.lsp.stop_client = original_stop_client
pcall(vim.api.nvim_del_augroup_by_name, "SoulLspLifecycle")
vim.api.nvim_buf_delete(buffer, { force = true })

local project_restore = require("soul.core.lifecycle.project")
local original_cwd = vim.fn.getcwd()

local function canonical_path(path)
	return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end
local temporary_root = vim.fn.tempname()
local older_project = temporary_root .. "/older"
local newer_project = temporary_root .. "/newer"
local registry_path = temporary_root .. "/projects.json"
local telescope_path = temporary_root .. "/telescope-projects.txt"
local telescope_project = temporary_root .. "/telescope=project"

vim.fn.mkdir(older_project, "p")
vim.fn.mkdir(newer_project, "p")
vim.fn.mkdir(telescope_project, "p")

local function escape_project_field(value)
	return tostring(value):gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("=", "\\=")
end

local function encode_project(title, path, activated, last_accessed)
	return table.concat({
		escape_project_field(title),
		escape_project_field(path),
		"w0",
		tostring(activated),
		tostring(last_accessed),
	}, "=")
end

vim.fn.writefile({
	encode_project("older", older_project, 1, 10),
	encode_project("inactive", newer_project, 0, 99),
	encode_project("telescope=project", telescope_project, 1, 20),
}, telescope_path)

assert(project_restore.restore(telescope_path), "Telescope project restore failed")
local restored_project = canonical_path(vim.fn.getcwd())
local expected_project = canonical_path(telescope_project)
assert(
	restored_project == expected_project,
	("project restore chose '%s'; expected '%s'"):format(restored_project, expected_project)
)
vim.cmd.cd(vim.fn.fnameescape(original_cwd))

vim.fn.writefile({
	vim.json.encode({
		[older_project] = { root = older_project, last_opened = 10 },
		[newer_project] = { root = newer_project, last_opened = 20 },
	}),
}, registry_path)

assert(project_restore.restore(registry_path), "project restore did not find a valid saved project")
assert(
	canonical_path(vim.fn.getcwd()) == canonical_path(newer_project),
	"project restore did not select the most recently opened valid project"
)
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(temporary_root, "rf")

print("Lifecycle, project restore, and idle LSP shutdown checks passed.")
