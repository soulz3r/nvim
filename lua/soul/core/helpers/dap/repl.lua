local M = {}

function M.setup(dap)
	local function get_repl_buffer()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "dap-repl" then
				return buf
			end
		end

		return nil
	end

	local function search_repl()
		local repl_buf = get_repl_buffer()

		if not repl_buf then
			dap.repl.open()
			repl_buf = get_repl_buffer()
		end

		if not repl_buf then
			vim.notify("Could not find the DAP REPL buffer.", vim.log.levels.WARN)
			return
		end

		local lines = vim.api.nvim_buf_get_lines(repl_buf, 0, -1, false)

		if #lines == 0 then
			vim.notify("The DAP REPL is empty.", vim.log.levels.INFO)
			return
		end

		local entries = {}

		for line_number, line in ipairs(lines) do
			table.insert(entries, { line = line, lnum = line_number })
		end

		local function jump_to_line(line_number)
			if not vim.api.nvim_buf_is_valid(repl_buf) then
				return
			end

			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == repl_buf then
					vim.api.nvim_set_current_win(win)
					vim.api.nvim_win_set_cursor(win, { line_number, 0 })
					return
				end
			end

			vim.cmd("sbuffer " .. repl_buf)
			vim.api.nvim_win_set_cursor(0, { line_number, 0 })
		end

		local ok, pickers = pcall(require, "telescope.pickers")

		if not ok then
			vim.ui.select(entries, {
				prompt = "Select DAP REPL line",
				format_item = function(entry)
					return string.format("%4d  %s", entry.lnum, entry.line)
				end,
			}, function(choice)
				if choice then
					jump_to_line(choice.lnum)
				end
			end)
			return
		end

		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		pickers
			.new({}, {
				prompt_title = "DAP REPL",
				finder = finders.new_table({
					results = entries,
					entry_maker = function(entry)
						return {
							value = entry,
							display = string.format("%4d  %s", entry.lnum, entry.line),
							ordinal = entry.line,
							lnum = entry.lnum,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr)
					actions.select_default:replace(function()
						local selection = action_state.get_selected_entry()
						actions.close(prompt_bufnr)

						if selection then
							jump_to_line(selection.value.lnum)
						end
					end)

					return true
				end,
			})
			:find()
	end

	local function open_or_focus_repl()
		local repl_buf = get_repl_buffer()

		if repl_buf then
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == repl_buf then
					vim.api.nvim_set_current_win(win)
					return
				end
			end
		end

		dap.repl.open()
	end

	return {
		open_or_focus = open_or_focus_repl,
		search = search_repl,
	}
end

return M
