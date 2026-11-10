local M = {
	"nvim-mini/mini.files",
	version = "*",
	dependencies = {
		"nvim-mini/mini.pick",
		"nvim-mini/mini.extra",
		"nvim-mini/mini.icons",
		"nvim-mini/mini.pairs",
		"nvim-mini/mini.ai",
		"nvim-mini/mini.surround",
		"nvim-mini/mini.notify",
		"nvim-mini/mini.sessions",
	},
}

function M.config()
	local MiniFiles = require("mini.files")
	local floats = require("soul.ui.floats")

	require("mini.icons").setup()
	require("mini.pairs").setup()
	require("mini.ai").setup()
	require("mini.surround").setup()

	local MiniNotify = require("mini.notify")

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

	local readonly_warning_ns = vim.api.nvim_create_namespace("soul.readonly_warning")
	pcall(vim.ui_detach, readonly_warning_ns)

	vim.ui_attach(readonly_warning_ns, { ext_messages = true }, function(event, kind, chunks)
		if event ~= "msg_show" or kind ~= "wmsg" then
			return false
		end

		local message = table.concat(vim.tbl_map(function(chunk)
			return chunk[2]
		end, chunks))

		if not message:find("W10", 1, true) and not message:find("Changing a readonly file", 1, true) then
			return false
		end

		vim.schedule(function()
			vim.notify("This buffer is read-only. Changes are disabled.", vim.log.levels.WARN, {
				title = "READ-ONLY",
			})
		end)

		return true
	end)

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

	local MiniSessions = require("mini.sessions")

	MiniSessions.setup({
		autoread = true,
		autowrite = true,
		directory = vim.fn.stdpath("state") .. "/sessions",
		file = "Session.vim",
		verbose = {
			read = false,
			write = false,
			delete = true,
		},
	})

	local show_hidden = false

	local function filter_show()
		return true
	end

	local function filter_hide(entry)
		return not vim.startswith(entry.name, ".")
	end

	local function toggle_hidden()
		show_hidden = not show_hidden

		MiniFiles.refresh({
			content = {
				filter = show_hidden and filter_show or filter_hide,
			},
		})
	end

	MiniFiles.setup({
		mappings = {
			go_in = "<CR>",
			go_in_plus = "L",
			go_out = ",",
			go_out_plus = "H",
			synchronize = "s",
		},

		options = {
			use_as_default_explorer = false,
			permanent_delete = false,
		},

		windows = {
			preview = true,
			width_focus = 25,
			width_nofocus = 15,
			width_preview = 20,
		},
		content = {
			filter = filter_hide,
		},
	})

	local function set_cwd()
		local entry = MiniFiles.get_fs_entry()

		if not entry or not entry.path then
			return vim.notify("Cursor is not on a valid entry", vim.log.levels.WARN)
		end

		local path = entry.path
		local directory = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)

		vim.cmd.cd(vim.fn.fnameescape(directory))
		vim.notify("Working directory: " .. vim.fn.fnamemodify(directory, ":~"))
	end

	local function open_entry()
		local entry = MiniFiles.get_fs_entry()

		if not entry or not entry.path then
			return
		end

		vim.ui.open(entry.path)
	end

	vim.api.nvim_create_autocmd("User", {
		pattern = "MiniFilesBufferCreate",
		callback = function(args)
			local buf = args.data.buf_id

			vim.keymap.set("n", "g~", set_cwd, {
				buffer = buf,
				desc = "Set working directory",
			})

			vim.keymap.set("n", "g.", toggle_hidden, {
				buffer = buf,
				desc = "Toggle hidden files",
			})

			vim.keymap.set("n", "gx", open_entry, {
				buffer = buf,
				desc = "Open with system application",
			})

			vim.keymap.set("n", "<CR>", function()
				MiniFiles.go_in({ close_on_file = true })
			end, {
				buffer = buf,
				desc = "Enter directory or open file and close explorer",
			})
		end,
	})

	function M.open(path)
		show_hidden = false
		MiniFiles.open(path or vim.fn.getcwd())
	end

	vim.keymap.set("n", "<leader>e", M.open, {
		desc = "Open Mini.files",
	})

	vim.keymap.set("n", "<leader>ss", function()
		local cwd = vim.fn.getcwd()
		local name = vim.fn.fnamemodify(cwd, ":t") .. "-" .. vim.fn.sha256(cwd):sub(1, 8) .. ".vim"
		MiniSessions.write(name)
	end, {
		desc = "Save project session",
	})

	vim.keymap.set("n", "<leader>sr", function()
		MiniSessions.select("read")
	end, {
		desc = "Restore project session",
	})

	vim.keymap.set("n", "<leader>sd", function()
		MiniSessions.select("delete")
	end, {
		desc = "Delete project session",
	})
end

return M
