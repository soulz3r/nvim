local M = {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
}

function M.config()
	local treesitter = require("nvim-treesitter")
	local started = {}
	local installing = {}

	local parsers_by_filetype = {
		c = { "c" },
		cpp = { "cpp" },
		lua = { "lua" },
		vim = { "vim" },
		help = { "vimdoc" },
		bash = { "bash" },
		json = { "json" },
		yaml = { "yaml" },
		markdown = { "markdown", "markdown_inline" },
		python = { "python" },
		rust = { "rust" },
		toml = { "toml" },
		javascript = { "javascript" },
		typescript = { "typescript" },
	}

	treesitter.setup({
		install_dir = vim.fn.stdpath("data") .. "/site",
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
		if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
			return false
		end

		if started[buf] then
			set_window_folds(buf)
			return true
		end

		local ok = pcall(vim.treesitter.start, buf)
		if ok then
			started[buf] = true
			set_window_folds(buf)
			return true
		end

		local filetype = vim.bo[buf].filetype
		local parsers = parsers_by_filetype[filetype]
		if not parsers or installing[filetype] then
			return false
		end

		installing[filetype] = true
		local install_ok, task = pcall(treesitter.install, parsers)
		if not install_ok then
			installing[filetype] = nil
			vim.notify(
				("Could not install Treesitter parsers for %s: %s"):format(filetype, tostring(task)),
				vim.log.levels.WARN,
				{ title = "Treesitter" }
			)
			return false
		end

		local await_ok, await_error = pcall(task.await, task, function(err)
			installing[filetype] = nil

			if err then
				vim.notify(
					("Treesitter parser installation failed for %s: %s"):format(filetype, tostring(err)),
					vim.log.levels.WARN,
					{ title = "Treesitter" }
				)
				return
			end

			-- More than one buffer may have opened while the parser was being
			-- installed. Start every still-loaded buffer of this filetype.
			for _, target in ipairs(vim.api.nvim_list_bufs()) do
				if
					vim.api.nvim_buf_is_valid(target)
					and vim.api.nvim_buf_is_loaded(target)
					and vim.bo[target].filetype == filetype
				then
					local start_ok = pcall(vim.treesitter.start, target)
					if start_ok then
						started[target] = true
						set_window_folds(target)
					end
				end
			end
		end)

		if not await_ok then
			installing[filetype] = nil
			vim.notify(
				("Could not await Treesitter parser installation for %s: %s"):format(filetype, tostring(await_error)),
				vim.log.levels.WARN,
				{ title = "Treesitter" }
			)
		end

		return false
	end

	local group = vim.api.nvim_create_augroup("SoulTreesitterFolds", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			start_buffer(args.buf)
		end,
	})

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

	-- BufNewFile can load this spec after FileType on some startup paths.
	vim.schedule(function()
		start_buffer(vim.api.nvim_get_current_buf())
	end)
end

return M
