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

print("Lifecycle scope and idle LSP shutdown checks passed.")
