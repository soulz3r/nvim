local M = {
	"nvim-mini/mini.nvim",
	version = "*",
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
	require("soul.core.helpers.mini.icons").setup()
	require("soul.core.helpers.mini.pairs").setup()
	require("soul.core.helpers.mini.ai").setup()
	require("soul.core.helpers.mini.surround").setup()
	require("soul.core.helpers.mini.notify").setup()
	require("soul.core.helpers.mini.sessions").setup()
end

return M
