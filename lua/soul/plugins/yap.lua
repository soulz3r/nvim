local M = {
	"soulz3r/yap.nvim",
	lazy = true,
}

M.config = function()
	local paths = require("soul.core.paths")

	require("yap").setup({
		projects_dir = paths.projects,
		telescope = false,
		keymaps = false,
	})
end

return M
