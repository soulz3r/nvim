local M = {
	"soulz3r/yap.nvim",
	lazy = true,
	dependencies = {
		"MunifTanjim/nui.nvim",
		"grapp-dev/nui-components.nvim",
	},
}

function M.config()
	local paths = require("soul.core.paths")

	require("yap").setup({
		projects_dir = paths.projects,
		telescope = false,
		keymaps = false,
	})
end

return M
