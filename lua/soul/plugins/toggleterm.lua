local M = {
	"akinsho/toggleterm.nvim",
	event = "VeryLazy",
}

function M.config()
	local floats = require("soul.core.helpers.ui.floats")
	local platform = require("soul.core.platform")
	local paths = require("soul.core.helpers.paths")
	local terminal_shell = vim.o.shell

	if platform.is_windows then
		-- ToggleTerm passes cmd as a PowerShell command string to termopen().
		-- Invoke the resolved executable explicitly so Store paths containing
		-- spaces are not split into separate command tokens.
		local quoted_powershell = "'" .. paths.pwsh:gsub("'", "''") .. "'"
		terminal_shell = "& " .. quoted_powershell .. " -NoLogo -NoExit"
	end
	local execs = {
		{ nil, "<M-1>", "Horizontal Terminal", "horizontal", 0.3 },
		{ nil, "<M-2>", "Vertical Terminal", "vertical", 0.4 },
		{ nil, "<M-3>", "Float Terminal", "float", nil },
	}

	local function get_buf_size()
		local cbuf = vim.api.nvim_get_current_buf()
		local bufinfo = vim.tbl_filter(function(buf)
			return buf.bufnr == cbuf
		end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]

		if bufinfo == nil then
			return { width = -1, height = -1 }
		end

		return {
			width = bufinfo.width,
			height = bufinfo.height,
		}
	end

	local function get_dynamic_terminal_size(direction, size)
		if direction ~= "float" and type(size) == "number" and size < 1 then
			local buf_sizes = get_buf_size()
			local buf_size = direction == "horizontal" and buf_sizes.height or buf_sizes.width

			return math.floor(buf_size * size)
		end

		return size
	end

	local exec_toggle = function(opts)
		local Terminal = require("toggleterm.terminal").Terminal

		local term = Terminal:new({
			cmd = opts.cmd,
			count = opts.count,
			direction = opts.direction,
		})

		term:toggle(opts.size, opts.direction)
	end

	local add_exec = function(opts)
		vim.keymap.set({ "n", "t" }, opts.keymap, function()
			exec_toggle({
				cmd = opts.cmd,
				count = opts.count,
				direction = opts.direction,
				size = opts.size(),
			})
		end, {
			desc = opts.label,
			noremap = true,
			silent = true,
		})
	end

	for i, exec in ipairs(execs) do
		local direction = exec[4]

		local opts = {
			cmd = exec[1] or terminal_shell,
			keymap = exec[2],
			label = exec[3],
			count = i + 100,
			direction = direction,
			size = function()
				return get_dynamic_terminal_size(direction, exec[5])
			end,
		}

		add_exec(opts)
	end

	require("toggleterm").setup({
		size = 10,
		open_mapping = [[<c-\>]],
		hide_numbers = true,
		shade_filetypes = {},
		shade_terminals = true,
		shading_factor = 2,
		start_in_insert = true,
		insert_mappings = true,
		persist_size = true,
		direction = "float",
		close_on_exit = true,
		shell = terminal_shell,

		float_opts = {
			border = floats.border,
			width = 50,
			height = 30,
			winblend = 1,
			highlights = {
				border = "FloatBorder",
				background = "NormalFloat",
			},
		},
		winbar = {
			enabled = false,
			name_formatter = function(term)
				return term.count
			end,
		},
	})

	local group = vim.api.nvim_create_augroup("SoulToggleTerm", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("TermOpen", {
		group = group,
		callback = function(ev)
			vim.keymap.set("n", "<LeftRelease>", "<LeftRelease>i", {
				buffer = ev.buf,
				silent = true,
				noremap = true,
				desc = "Enter terminal input after mouse release",
			})

			if vim.bo[ev.buf].filetype ~= "toggleterm" then
				return
			end

			vim.keymap.set("n", "q", "<cmd>close<CR>", {
				buffer = ev.buf,
				silent = true,
				desc = "Close terminal",
			})
		end,
	})

	vim.api.nvim_create_autocmd("TermEnter", {
		group = group,
		callback = function(ev)
			if vim.bo[ev.buf].filetype == "toggleterm" then
				vim.cmd.startinsert()
			end
		end,
	})
end

return M
