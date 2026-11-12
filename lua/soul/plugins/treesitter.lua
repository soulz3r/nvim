local M = {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
}

function M.config()
	local treesitter = require("nvim-treesitter")
	local started = {}

	local filetypes = {
		"c",
		"cpp",
		"lua",
		"vim",
		"help",
		"bash",
		"json",
		"yaml",
		"markdown",
		"python",
		"rust",
		"toml",
		"javascript",
		"typescript",
	}

	treesitter.setup({
		install_dir = vim.fn.stdpath("data") .. "/site",
	})

	local install_task = treesitter.install({
		"c",
		"cpp",
		"lua",
		"vim",
		"vimdoc",
		"bash",
		"json",
		"yaml",
		"markdown",
		"markdown_inline",
		"python",
		"rust",
		"toml",
		"javascript",
		"typescript",
	})

	local function set_window_folds(buf)
		if not started[buf] or not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		for _, win in ipairs(vim.fn.win_findbuf(buf)) do
			if vim.api.nvim_win_is_valid(win) then
				vim.wo[win].foldmethod = "expr"
				vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			end
		end
	end

	local function start_buffer(buf)
		if not vim.api.nvim_buf_is_valid(buf) then
			return false
		end

		local ok = pcall(vim.treesitter.start, buf)
		if not ok then
			started[buf] = nil
			return false
		end

		started[buf] = true
		set_window_folds(buf)
		return true
	end

	local group = vim.api.nvim_create_augroup("SoulTreesitterFolds", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = filetypes,
		callback = function(args)
			start_buffer(args.buf)
		end,
	})

	-- Parser installation is asynchronous. Retry buffers that opened while
	-- their parser was still compiling.
	install_task:await(function(err)
		if err then
			vim.notify(
				"Treesitter parser installation reported an error: " .. tostring(err),
				vim.log.levels.WARN,
				{ title = "Treesitter" }
			)
		end

		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf)
				and vim.tbl_contains(filetypes, vim.bo[buf].filetype)
			then
				start_buffer(buf)
			end
		end
	end)

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = group,
		callback = function(args)
			local buf = args.buf
			if buf and vim.api.nvim_buf_is_valid(buf) then
				set_window_folds(buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			started[args.buf] = nil
		end,
	})
end

return M
