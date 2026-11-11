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
			lsp_progress = {
				enable = true,
				level = "INFO",
				duration_last = 3000,
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

		vim.notify = MiniNotify.make_notify({
			ERROR = { duration = 10000, hl_group = "DiagnosticError" },
			WARN = { duration = 7000, hl_group = "DiagnosticWarn" },
			INFO = { duration = 5000, hl_group = "DiagnosticInfo" },
			DEBUG = { duration = 4000, hl_group = "DiagnosticHint" },
			TRACE = { duration = 4000, hl_group = "DiagnosticOk" },
			OFF = { duration = 0, hl_group = "MiniNotifyNormal" },
		})

		local message_ns = vim.api.nvim_create_namespace("soul.message_notifications")
		if vim.ui_detach then
			pcall(vim.ui_detach, message_ns)
		end

		if vim.ui_attach then
			vim.ui_attach(message_ns, { ext_messages = true }, function(event, kind, chunks)
				if event ~= "msg_show" then
					return false
				end

				-- Keep interactive prompts native. These require input rather than
				-- merely reporting something, so turning them into notifications
				-- would make command-line workflows awkward or break them.
				if kind == "return_prompt" then
					return false
				end

				local message = table.concat(vim.tbl_map(function(chunk)
					return type(chunk) == "table" and tostring(chunk[2] or "") or tostring(chunk)
				end, chunks or {}))
				message = vim.trim(message)

				if message == "" then
					return true
				end

				local levels = {
					emsg = { level = vim.log.levels.ERROR, title = "ERROR" },
					echoerr = { level = vim.log.levels.ERROR, title = "ERROR" },
					wmsg = { level = vim.log.levels.WARN, title = "WARNING" },
					echomsg = { level = vim.log.levels.INFO, title = "MESSAGE" },
					echo = { level = vim.log.levels.INFO, title = "MESSAGE" },
					lua_print = { level = vim.log.levels.INFO, title = "PRINT" },
					quickfix = { level = vim.log.levels.WARN, title = "QUICKFIX" },
				}
				local notification = levels[kind] or {
					level = vim.log.levels.INFO,
					title = "NEOVIM",
				}

				if message:find("W10", 1, true)
					or message:find("Changing a readonly file", 1, true)
				then
					message = "This buffer is read-only. Changes are disabled."
					notification = {
						level = vim.log.levels.WARN,
						title = "READ-ONLY",
					}
				end

				vim.schedule(function()
					vim.notify(message, notification.level, {
						title = notification.title,
					})
				end)

				-- Consume the message so it never reaches the command area.
				return true
			end)
		end

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
