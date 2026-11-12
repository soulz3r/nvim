local M = {
	"nvim-mini/mini.files",
	version = "*",
	dependencies = {
		"nvim-mini/mini.icons",
	},
	keys = {
		{
			"<leader>e",
			function()
				require("mini.files").open(vim.fn.getcwd())
			end,
			desc = "Open Mini.files",
		},
	},
}
function M.config()
	local MiniFiles = require("mini.files")
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

	local function synchronize_without_confirmation()
		local original_confirm = vim.fn.confirm

		vim.fn.confirm = function(message, choices, default, kind)
			if choices == "&Yes\n&No\n&Cancel" and default == 1 and kind == "Question" then
				return 1
			end

			return original_confirm(message, choices, default, kind)
		end

		local ok, result = xpcall(MiniFiles.synchronize, debug.traceback)
		vim.fn.confirm = original_confirm

		if not ok then
			error(result, 0)
		end

		return result
	end

	MiniFiles.setup({
		mappings = {
			go_in = "<CR>",
			go_in_plus = "L",
			go_out = ",",
			go_out_plus = "H",
			synchronize = "<leader>w",
		},
		options = {
			use_as_default_explorer = true,
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
		vim.notify(
			"Working directory: " .. vim.fn.fnamemodify(directory, ":~"),
			vim.log.levels.INFO,
			{ title = "Working Directory" }
		)
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

			vim.keymap.set("n", "<leader>w", synchronize_without_confirmation, {
				buffer = buf,
				desc = "Synchronize changes without confirmation",
			})

			vim.keymap.set("n", "<CR>", function()
				MiniFiles.go_in({ close_on_file = true })
			end, {
				buffer = buf,
				desc = "Enter directory or open file and close explorer",
			})
		end,
	})
end
return M
