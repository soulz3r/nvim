local M = {
	"akinsho/toggleterm.nvim",
	event = "VeryLazy",
}

function M.config()
	local floats = require("soul.core.helpers.ui.floats")
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
			cmd = exec[1] or vim.o.shell,
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
		shell = vim.o.shell,

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

	vim.cmd([[
    augroup terminal_setup
      autocmd!
      autocmd TermOpen * nnoremap <buffer><LeftRelease> <LeftRelease>i
    augroup END
  ]])

	local function set_terminal_keymaps(bufnr)
		local opts = {
			buffer = bufnr,
			noremap = true,
			silent = true,
		}
	end

	vim.api.nvim_create_autocmd("TermEnter", {
		pattern = "*",
		callback = function(args)
			set_terminal_keymaps(args.buf)
			vim.cmd("startinsert")
		end,
	})
end

return M
