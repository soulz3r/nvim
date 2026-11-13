local Scope = require("soul.core.lifecycle.scope")

local M = {
	-- A client is eligible for shutdown only after it has no attached buffers.
	-- Hidden buffers remain attached and therefore keep their server alive.
	idle_timeout = 10 * 60 * 1000,
}

local timers = {}

local function cancel_timer(client_id)
	local scope = timers[client_id]
	if not scope then
		return
	end

	timers[client_id] = nil
	scope:close()
end

local function has_attached_buffers(client)
	for bufnr in pairs(client.attached_buffers or {}) do
		if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
			return true
		end
	end

	return false
end

local function schedule_shutdown(client_id)
	local client = vim.lsp.get_client_by_id(client_id)
	if not client or client:is_stopped() or has_attached_buffers(client) then
		cancel_timer(client_id)
		return
	end

	cancel_timer(client_id)

	local scope = Scope.new()
	timers[client_id] = scope

	local timer = scope:timer()
	timer:start(M.idle_timeout, 0, function()
		vim.schedule(function()
			if timers[client_id] ~= scope then
				return
			end

			timers[client_id] = nil

			local idle_client = vim.lsp.get_client_by_id(client_id)
			if idle_client and not idle_client:is_stopped() and not has_attached_buffers(idle_client) then
				vim.lsp.stop_client(client_id, false)
			end

			scope:close()
		end)
	end)
end

function M.setup()
	for client_id in pairs(timers) do
		cancel_timer(client_id)
	end

	local group = vim.api.nvim_create_augroup("SoulLspLifecycle", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(args)
			cancel_timer(args.data.client_id)
		end,
	})

	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		callback = function(args)
			local client_id = args.data.client_id

			-- LspDetach fires during the detach operation. Check the client's
			-- final attachment set on the next event-loop turn.
			vim.schedule(function()
				schedule_shutdown(client_id)
			end)
		end,
	})

	vim.api.nvim_create_autocmd("LspStop", {
		group = group,
		callback = function(args)
			if args.data and args.data.client_id then
				cancel_timer(args.data.client_id)
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			for client_id in pairs(timers) do
				cancel_timer(client_id)
			end
		end,
	})
end

function M._has_attached_buffers(client)
	return has_attached_buffers(client)
end

return M
