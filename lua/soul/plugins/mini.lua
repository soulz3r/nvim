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

	require("mini.icons").setup()
	require("mini.pairs").setup()
	require("mini.ai").setup()
	require("mini.surround").setup()

	require("mini.notify").setup({
		window = {
			config = {
				border = "rounded",
			},
			max_width_share = 0.30,
			max_height_share = 0.18,
			winblend = 10,
		},
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
