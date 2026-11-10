local M = {
	"soulz3r/yap.nvim",
	lazy = true,
}

function M.config()
	local paths = require("soul.core.paths")

	require("yap").setup({
		telescope = false,
		keymaps = false,
		projects_dir = paths.projects,
	})
end

return M
