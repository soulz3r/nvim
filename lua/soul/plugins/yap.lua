return {
	"soulz3r/yap.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-telescope/telescope-project.nvim",
	},
	config = function()
		require("yap").setup({
			projects_dir = require("soul.core.paths").projects,
			telescope = true,
			keymaps = true,
		})
	end,
}
