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
	require("soul.core.helpers.mini.files").setup()
end

return M
