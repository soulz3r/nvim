return {
	"taigrr/cyberpunk.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		transparent = true, -- set true for transparent background
		italic_comments = true, -- italicize comments
		italic_keywords = false, -- italicize keywords
		bold_functions = true, -- bold function names
		bold_keywords = true, -- bold keywords (default)
		overrides = {}, -- override specific highlight groups
	},
	config = function()
		require("cyberpunk").setup({
        vim.cmd.colorscheme("cyberpunk")
		})
	end,
}
