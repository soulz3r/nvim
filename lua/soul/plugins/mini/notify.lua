return {
	"nvim-mini/mini.notify",
	version = "*",
	config = function()
		local MiniNotify = require("mini.notify")
		local floats = require("soul.core.helpers.ui.floats")

		local function format_notification(notif)
			local message = vim.trim(tostring(notif.msg or "")):gsub("%s+", " ")
			local timestamp = notif.ts_update or notif.ts_add
			local time = timestamp and vim.fn.strftime("%H:%M:%S", math.floor(timestamp)) or nil

			return time and (message .. " │ " .. time) or message
		end

		MiniNotify.setup({
			content = {
				format = format_notification,
				sort = MiniNotify.default_sort,
			},
			-- Progress is handled below, once per client instead of once per token.
			lsp_progress = {
				enable = false,
			},
			window = {
				config = function()
					local has_statusline = vim.o.laststatus > 0
					local padding = vim.o.cmdheight + (has_statusline and 1 or 0)
					local active = vim.tbl_filter(function(notif)
						return notif.ts_remove == nil
					end, MiniNotify.get_all())
					local latest = MiniNotify.default_sort(active)[1]
					local titles = {
						ERROR = "ERROR",
						WARN = "WARNING",
						INFO = "INFO",
						DEBUG = "DEBUG",
						TRACE = "TRACE",
						OFF = "OFF",
					}
					local title = latest and (titles[latest.level] or latest.level) or "INFO"

					return {
						anchor = "SE",
						col = vim.o.columns,
						row = vim.o.lines - padding,
						border = floats.border,
						title = " " .. title .. " ",
					}
				end,
				max_width_share = 0.30,
				max_height_share = 0.18,
				winblend = 10,
			},
		})

		local mini_notify = MiniNotify.make_notify({
			ERROR = { duration = 10000, hl_group = "DiagnosticError" },
			WARN = { duration = 7000, hl_group = "DiagnosticWarn" },
		})

		-- Keep routine INFO messages quiet while preserving warnings and errors.
		vim.notify = function(message, level, opts)
			level = level or vim.log.levels.INFO

			if level ~= vim.log.levels.ERROR and level ~= vim.log.levels.WARN then
				return
			end

			return mini_notify(message, level, opts)
		end

		-- LuaLS can report the same workspace operation under multiple progress
		-- tokens. Track those tokens, but render only one notification per client.
		local progress_by_client = {}
		local progress_group = vim.api.nvim_create_augroup("SoulLspProgress", {
			clear = true,
		})

		local function render_progress(client_id, state)
			local latest

			for _, progress in pairs(state.tokens) do
				if not latest or progress.updated_at > latest.updated_at then
					latest = progress
				end
			end

			if not latest then
				vim.defer_fn(function()
					if progress_by_client[client_id] ~= state or next(state.tokens) ~= nil then
						return
					end

					MiniNotify.remove(state.notification_id)
					progress_by_client[client_id] = nil
				end, 1000)
				return
			end

			local message = latest.title or latest.message or "Working"
			if latest.title and latest.message and latest.message ~= latest.title then
				message = message .. ": " .. latest.message
			end
			if type(latest.percentage) == "number" then
				message = message .. (" (%d%%)"):format(math.floor(latest.percentage))
			end

			message = state.client_name .. ": " .. message
			local data = {
				source = "lsp_progress",
				client_id = client_id,
				client_name = state.client_name,
			}

			if state.notification_id then
				MiniNotify.update(state.notification_id, {
					msg = message,
					data = data,
				})
			else
				state.notification_id = MiniNotify.add(
					message,
					"INFO",
					"MiniNotifyLspProgress",
					data
				)
			end
		end

		vim.api.nvim_create_autocmd("LspProgress", {
			group = progress_group,
			callback = function(event)
				local client_id = event.data.client_id
				local client = vim.lsp.get_client_by_id(client_id)
				local params = event.data.params
				local value = params and params.value
				local token = params and params.token

				if not client or token == nil or type(value) ~= "table" then
					return
				end

				local state = progress_by_client[client_id]
				if not state then
					state = {
						client_name = client.name,
						tokens = {},
					}
					progress_by_client[client_id] = state
				end

				if value.kind == "end" then
					state.tokens[token] = nil
				else
					local previous = state.tokens[token] or {}
					state.tokens[token] = {
						title = value.title or previous.title,
						message = value.message,
						percentage = value.percentage,
						updated_at = vim.uv.hrtime(),
					}
				end

				render_progress(client_id, state)
			end,
		})

		vim.api.nvim_create_autocmd("LspDetach", {
			group = progress_group,
			callback = function(event)
				local client_id = event.data.client_id
				local state = progress_by_client[client_id]

				if state then
					MiniNotify.remove(state.notification_id)
					progress_by_client[client_id] = nil
				end
			end,
		})

		vim.keymap.set("n", "<leader>nc", MiniNotify.clear, {
			desc = "Clear notifications",
		})

		local function show_notification_history()
			local width = math.floor(vim.o.columns * 0.70)
			local height = math.floor(vim.o.lines * 0.60)
			local row = math.floor((vim.o.lines - height) / 2 - 1)
			local col = math.floor((vim.o.columns - width) / 2)
			local notifications = MiniNotify.default_sort(vim.tbl_values(MiniNotify.get_all()))
			local lines = {}

			for _, notif in ipairs(notifications) do
				table.insert(lines, format_notification(notif))
			end

			if #lines == 0 then
				lines[1] = "No notification history"
			end

			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

			for i, notif in ipairs(notifications) do
				vim.api.nvim_buf_add_highlight(buf, -1, notif.hl_group or "MiniNotifyNormal", i - 1, 0, -1)
			end

			vim.bo[buf].buftype = "nofile"
			vim.bo[buf].bufhidden = "wipe"
			vim.bo[buf].swapfile = false
			vim.bo[buf].modifiable = false
			vim.bo[buf].filetype = "mininotify-history"

			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				style = "minimal",
				border = floats.border,
				title = " History ",
				title_pos = "center",
				width = width,
				height = height,
				row = row,
				col = col,
			})

			vim.wo[win].wrap = true
			vim.wo[win].cursorline = true
		end

		vim.keymap.set("n", "<leader>nh", show_notification_history, {
			desc = "Show notification history",
		})
	end,
}
