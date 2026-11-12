local M = {}

function M.setup(dap, dapui)
	dapui.setup({
		icons = {
			expanded = "▾",
			collapsed = "▸",
			current_frame = "▸",
		},
		mappings = {
			expand = { "<CR>", "<2-LeftMouse>" },
			open = "o",
			remove = "d",
			edit = "e",
			toggle = "t",
			expand_all = "E",
		},
		controls = {
			enabled = true,
			element = "repl",
			icons = {
				pause = "⏸",
				play = "▶",
				step_into = "↴",
				step_over = "↷",
				step_out = "↰",
				step_back = "←",
				run_last = "↻",
				terminate = "■",
				disconnect = "⏏",
			},
		},
		floating = {
			border = "rounded",
			mappings = {
				close = { "q", "<Esc>" },
			},
		},
		windows = {
			indent = 1,
		},
	})

	-- =========================================================
	-- Restore source window after debugging
	-- =========================================================

	local source_context

	local function remember_source()
		local win = vim.api.nvim_get_current_win()

		if not vim.api.nvim_win_is_valid(win) then
			return
		end

		local buf = vim.api.nvim_win_get_buf(win)

		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		source_context = {
			win = win,
			buf = buf,
			cursor = vim.api.nvim_win_get_cursor(win),
		}
	end

	local function restore_source()
		local context = source_context

		if not context then
			return
		end

		vim.schedule(function()
			if not vim.api.nvim_win_is_valid(context.win) then
				source_context = nil
				return
			end

			vim.api.nvim_set_current_win(context.win)

			if vim.api.nvim_buf_is_valid(context.buf) then
				vim.api.nvim_win_set_buf(context.win, context.buf)

				local count = vim.api.nvim_buf_line_count(context.buf)
				local line = math.max(1, math.min(context.cursor[1], count))

				pcall(vim.api.nvim_win_set_cursor, context.win, {
					line,
					context.cursor[2],
				})
			end

			source_context = nil
		end)
	end

	dap.listeners.before.event_initialized["soul_dap_source"] = function()
		remember_source()
		dapui.open()
	end

	dap.listeners.after.event_exited["soul_dap_source"] = restore_source
	dap.listeners.after.event_terminated["soul_dap_source"] = restore_source
end

return M
