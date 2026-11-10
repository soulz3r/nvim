local M = {
	"soulz3r/yap.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"grapp-dev/nui-components.nvim",
	},
}

function M.config()
	local palette = require("soul.ui.colors").palette

	require("yap").setup({
		projects_dir = require("soul.core.paths").projects,
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