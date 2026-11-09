local M = {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
}

function M.config()
	require("lualine").setup({
		options = {
			icons_enabled = true,
			theme = "auto",
			component_separators = "",
			section_separators = "",
			globalstatus = true,
			always_show_tabline = false,
			refresh = {
				statusline = 1000,
				tabline = 1000,
				winbar = 1000,
			},
		},

		sections = {
			lualine_a = {
				{
					"mode",
					fmt = function(mode)
						local modes = {
							NORMAL = "N",
							INSERT = "I",
							VISUAL = "V",
							["V-LINE"] = "VL",
							["V-BLOCK"] = "VB",
							REPLACE = "R",
							COMMAND = "C",
							TERMINAL = "T",
						}
						return modes[mode] or mode
					end,
				},
			},
			lualine_b = {
				{
					"branch",
					icon = "",
					padding = { left = 1, right = 1 },
				},
			},
			lualine_c = {
				{
					"filename",
					path = 1,
					symbols = {
						modified = " ●",
						readonly = " ",
						unnamed = "[No Name]",
					},
				},
			},
			lualine_x = {
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					sections = { "error", "warn" },
					always_visible = false,
				},
				{
					"filetype",
					icon_only = true,
					padding = { left = 1, right = 1 },
				},
			},
			lualine_y = {},
			lualine_z = {
				{
					"location",
					padding = { left = 1, right = 1 },
				},
			},
		},

		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{
					"filename",
					path = 1,
				},
			},
			lualine_x = {
				"location",
			},
			lualine_y = {},
			lualine_z = {},
		},

		tabline = {},
		winbar = {},
		inactive_winbar = {},
		extensions = {},
	})
end

return M
