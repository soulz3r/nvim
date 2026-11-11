local M = {}

function M.register(state)
	local animation = state.animation
	local footer = state.footer

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "alpha",
		callback = function()
			vim.opt_local.foldenable = false
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.cursorline = false
			animation.start()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "AlphaReady",
		callback = animation.start,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			if vim.bo[args.buf].filetype == "alpha" then
				footer.invalidate(vim.fn.getcwd())
				footer.update()
				pcall(vim.cmd.AlphaRedraw)
				animation.start()
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		callback = function(args)
			if vim.bo[args.buf].filetype == "alpha" then
				animation.stop()
			end
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function()
			footer.update()
			pcall(vim.cmd.AlphaRedraw)
		end,
	})

	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			if vim.bo.filetype == "alpha" then
				footer.update()
				pcall(vim.cmd.AlphaRedraw)
			end
		end,
	})

	if vim.bo.filetype == "alpha" then
		animation.start()
	end
end

return M
