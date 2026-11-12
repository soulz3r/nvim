local M = {
	"soulz3r/yap.nvim",
	branch = "main",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-telescope/telescope-project.nvim",
	},
}

function M.config()
	local palette = require("soul.core.helpers.ui.colors").palette

	require("yap").setup({
		projects_dir = require("soul.core.helpers.paths").projects,
		telescope = true,
		keymaps = true,
		highlights = {
			normal = { fg = palette.foreground, bg = "NONE" },
			border = { fg = palette.border, bg = "NONE" },
			title = { fg = palette.green, bg = "NONE", bold = true },
			section_title = { fg = palette.green, bold = true },
			muted = { fg = palette.muted },
			success = { fg = palette.green },
			warning = { fg = palette.yellow },
			error = { fg = palette.red },
		},
	})
end

return M
