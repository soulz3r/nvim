return {
	"MeanderingProgrammer/render-markdown.nvim",
	after = { "nvim-treesitter" },
	requires = { "echasnovski/mini.nvim", opt = true },
	config = function()
		require("render-markdown").setup({
			html = { enabled = false },
			latex = { enabled = false },
		})
	end,
}
