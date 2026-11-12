local M = {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
}

function M.config()
	local palette = require("soul.core.helpers.ui.colors").palette
	local project_status = ""
	local attached_clients = {}

	local function has_project_status()
		local ok, registry = pcall(require, "yap.project_registry")
		if not ok or type(registry.status) ~= "function" then
			project_status = ""
			return false
		end

		local status_ok, status = pcall(registry.status)
		if not status_ok or type(status) ~= "string" then
			project_status = ""
			return false
		end

		project_status = status
		return project_status ~= ""
	end

	local function has_lsp_clients()
		attached_clients = vim.lsp.get_clients({ bufnr = 0 })
		return #attached_clients > 0
	end

	require("lualine").setup({
		options = {
			icons_enabled = true,
			theme = "everforest",
			component_separators = "",
			section_separators = "",
			globalstatus = true,
			disabled_filetypes = {
				statusline = { "alpha", "project-output" },
				winbar = { "alpha", "project-output" },
			},
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
			lualine_y = {
				{
					function()
						return project_status
					end,
					cond = has_project_status,
					color = { fg = palette.green },
				},
				{
					function()
						return "󰒋 " .. #attached_clients
					end,
					cond = has_lsp_clients,
					color = { fg = palette.teal },
				},
			},
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
