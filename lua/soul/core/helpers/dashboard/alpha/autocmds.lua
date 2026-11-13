local Scope = require("soul.core.lifecycle.scope")

local M = {}

local function is_alpha(bufnr)
	return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "alpha"
end

local function apply_button_keymaps(bufnr)
	if not is_alpha(bufnr) then
		return
	end

	for _, item in ipairs(require("soul.core.helpers.dashboard.buttons").items) do
		vim.keymap.set("n", item.key, item.command, {
			buffer = bufnr,
			noremap = true,
			silent = true,
			nowait = true,
			desc = "Alpha: " .. vim.trim(item.label),
		})
	end
end

local function release_dashboard_modules()
	local prefix = "soul.core.helpers.dashboard."

	for name in pairs(package.loaded) do
		if name:sub(1, #prefix) == prefix then
			package.loaded[name] = nil
		end
	end
end

function M.register(state)
	local animation = state.animation
	local footer = state.footer
	local scope = Scope.new()
	local group = scope:augroup("SoulAlpha")
	local released = false

	local function release()
		if released then
			return
		end
		released = true

		scope:close()

		-- The dashboard is a one-shot startup surface. Drop its frame data and
		-- helper-module cache only when its buffer is actually destroyed.
		state.animation = nil
		state.logo = nil
		state.footer = nil
		state.animation_data = nil
		state.next_animation_frame = nil
		release_dashboard_modules()
	end

	scope:add(function()
		animation.close()
	end)

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "alpha",
		callback = function(args)
			vim.opt_local.foldenable = false
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.cursorline = false
			apply_button_keymaps(args.buf)
			animation.start()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "AlphaReady",
		callback = function()
			apply_button_keymaps(vim.api.nvim_get_current_buf())
			animation.start()
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(args)
			if is_alpha(args.buf) then
				apply_button_keymaps(args.buf)
				footer.invalidate(vim.fn.getcwd())
				footer.update()
				vim.cmd.AlphaRedraw()
				animation.start()
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		group = group,
		callback = function(args)
			if is_alpha(args.buf) then
				-- A temporary window or picker can take focus without destroying
				-- the dashboard. Pause the timer, but keep its scope reusable.
				animation.stop()
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			if is_alpha(args.buf) then
				release()
			end
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "VeryLazy",
		callback = function()
			footer.update()
			vim.cmd.AlphaRedraw()
		end,
	})

	vim.api.nvim_create_autocmd("DirChanged", {
		group = group,
		callback = function()
			if vim.bo.filetype == "alpha" then
				footer.update()
				vim.cmd.AlphaRedraw()
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = release,
	})

	if vim.bo.filetype == "alpha" then
		apply_button_keymaps(vim.api.nvim_get_current_buf())
		animation.start()
	end
end

return M
