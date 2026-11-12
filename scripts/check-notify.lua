local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

assert(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")

local notifications = {}
local next_id = 0
local MiniNotify = {}

function MiniNotify.setup(opts)
	MiniNotify.options = opts
end

function MiniNotify.default_sort(items)
	table.sort(items, function(a, b)
		return (a.ts_update or a.ts_add) > (b.ts_update or b.ts_add)
	end)
	return items
end

function MiniNotify.get_all()
	return notifications
end

function MiniNotify.add(message, level, hl_group, data)
	next_id = next_id + 1
	notifications[next_id] = {
		msg = message,
		level = level,
		hl_group = hl_group,
		data = data,
		ts_add = vim.uv.hrtime(),
		ts_update = vim.uv.hrtime(),
	}
	return next_id
end

function MiniNotify.update(id, changes)
	local notification = notifications[id]
	assert(notification, "cannot update a missing notification")
	for key, value in pairs(changes) do
		notification[key] = value
	end
	notification.ts_update = vim.uv.hrtime()
end

function MiniNotify.remove(id)
	if notifications[id] then
		notifications[id].ts_remove = vim.uv.hrtime()
	end
end

function MiniNotify.make_notify()
	return function(message, level, opts)
		return MiniNotify.add(message, level, nil, opts and opts.data)
	end
end

function MiniNotify.clear()
	for id in pairs(notifications) do
		MiniNotify.remove(id)
	end
end

package.preload["mini.notify"] = function()
	return MiniNotify
end

local original_notify = vim.notify
local original_defer_fn = vim.defer_fn
local original_get_client = vim.lsp.get_client_by_id
local deferred = {}
local clients = {
	[1] = { id = 1, name = "clangd" },
	[2] = { id = 2, name = "clangd" },
}

vim.defer_fn = function(callback, delay)
	deferred[#deferred + 1] = {
		callback = callback,
		delay = delay,
	}
end

vim.lsp.get_client_by_id = function(client_id)
	return clients[client_id]
end

require("soul.core.helpers.mini.notify").setup()

local function progress(client_id, token, value)
	vim.api.nvim_exec_autocmds("LspProgress", {
		data = {
			client_id = client_id,
			params = {
				token = token,
				value = value,
			},
		},
	})
end

local function detach(client_id)
	vim.api.nvim_exec_autocmds("LspDetach", {
		data = {
			client_id = client_id,
		},
	})
end

local function active_notifications()
	local active = {}
	for id, notification in pairs(notifications) do
		if notification.ts_remove == nil then
			active[id] = notification
		end
	end
	return active
end

local function active_count()
	local count = 0
	for _ in pairs(active_notifications()) do
		count = count + 1
	end
	return count
end

local function run_latest_cleanup()
	local cleanup = deferred[#deferred]
	assert(cleanup and cleanup.delay == 1000, "LSP progress cleanup must be deferred")
	cleanup.callback()
end

-- Two clients using the same server name should share one visible notification.
progress(1, "first", { kind = "begin", title = "Indexing", percentage = 10 })
progress(2, "second", { kind = "begin", title = "Background work", percentage = 20 })
assert(active_count() == 1, "Concurrent clients for one server must share one progress notification")

-- Ending one client's token must not remove progress still owned by another client.
progress(1, "first", { kind = "end" })
assert(active_count() == 1, "Ending one client must preserve another client's progress")

-- A new token must invalidate an older delayed cleanup callback.
progress(2, "second", { kind = "end" })
local stale_cleanup = deferred[#deferred]
assert(stale_cleanup, "Ending the last token must schedule cleanup")
progress(2, "third", { kind = "begin", title = "New operation" })
stale_cleanup.callback()
assert(active_count() == 1, "A stale cleanup callback must not remove newer progress")
progress(2, "third", { kind = "end" })
run_latest_cleanup()
assert(active_count() == 0, "Completed progress must be removed after its cleanup delay")

-- Detaching one of multiple clients must preserve the remaining client's work.
progress(1, "detach-one", { kind = "begin", title = "Client one" })
progress(2, "detach-two", { kind = "begin", title = "Client two" })
detach(1)
assert(active_count() == 1, "Detaching one client must preserve the other client's progress")
local remaining
for _, notification in pairs(active_notifications()) do
	remaining = notification
end
assert(remaining and remaining.data.client_id == 2, "Progress should be attributed to the remaining client")

detach(2)
run_latest_cleanup()
assert(active_count() == 0, "Detaching the final client must clean up its progress notification")

vim.notify = original_notify
vim.defer_fn = original_defer_fn
vim.lsp.get_client_by_id = original_get_client

print("Mini Notify progress lifecycle tests passed.")
