local M = {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-mini/mini.icons",
	},
}

function M.config()
	require("render-markdown").setup({
		html = { enabled = false },
		latex = { enabled = false },
	})
end

return M
