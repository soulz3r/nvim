local M = {
	"soulz3r/yap.nvim",
	branch = "main",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "CProjectInfo", "CSwitchHeader" },
	keys = {
		{ "<leader>pp", desc = "Open YAP project picker" },
		{ "<leader>pr", desc = "Build and run current project" },
		{ "<leader>pb", desc = "Build current project" },
		{ "<leader>pc", desc = "Clean current project" },
		{ "<leader>pB", desc = "Clean and rebuild current project" },
		{ "<leader>pS", desc = "Select project build script" },
		{ "<leader>pe", desc = "Select project executable" },
		{ "<leader>ps", desc = "Stop project process" },
		{ "<leader>pR", desc = "Rerun last project executable" },
	},
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
