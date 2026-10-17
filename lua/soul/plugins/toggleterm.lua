local M = {
	"akinsho/toggleterm.nvim",
	event = "VeryLazy",
}

function M.config()
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
		persist_size = false,
		direction = "float",
		close_on_exit = true,
		shell = vim.o.shell,

		float_opts = {
			border = "rounded",
			width = 45,
			height = 30,
			winblend = 1,
			highlights = {
				border = "Normal",
				background = "Normal",
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
      autocmd TermEnter * startinsert!
    augroup END
  ]])

	local terminal_opts = {
		noremap = true,
		silent = true,
	}

	function _G.set_terminal_keymaps()
		vim.api.nvim_buf_set_keymap(0, "t", "<M-h>", [[<C-\><C-n><C-W>h]], terminal_opts)
		vim.api.nvim_buf_set_keymap(0, "t", "<M-j>", [[<C-\><C-n><C-W>j]], terminal_opts)
		vim.api.nvim_buf_set_keymap(0, "t", "<M-k>", [[<C-\><C-n><C-W>k]], terminal_opts)
		vim.api.nvim_buf_set_keymap(0, "t", "<M-l>", [[<C-\><C-n><C-W>l]], terminal_opts)
	end

	vim.api.nvim_create_autocmd("TermEnter", {
		pattern = "*",
		callback = function()
			_G.set_terminal_keymaps()
			vim.cmd("startinsert")
		end,
	})
end

return M
