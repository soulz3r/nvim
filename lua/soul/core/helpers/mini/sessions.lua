local M = {}
local configured = false

function M.setup()
	if configured then
		return
	end

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

	configured = true
end

return M
