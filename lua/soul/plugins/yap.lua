local M = {
	"soulz3r/yap.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-telescope/telescope-project.nvim",
	},
}
function M.config()
	require("yap").setup({
		projects_dir = require("soul.core.paths").projects,
		telescope = true,
		keymaps = true,
	})
end

return M
