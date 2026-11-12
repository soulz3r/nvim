local M = {}

-- Plain dashboard button data. This module does not depend on Alpha.
-- Icon names are resolved by the consumer using the shared icon registry.
M.items = {
	{
		key = "f",
		icon_group = "ui",
		icon = "Files",
		label = "Find file",
		command = "<cmd>Telescope find_files<CR>",
		highlight = "AlphaBlue",
	},

	{
		key = "e",
		icon_group = "ui",
		icon = "Folder",
		label = "Open Explorer",
		command = "<cmd>lua require('lazy').load({ plugins = { 'mini.files' } }); require('mini.files').open(vim.fn.getcwd())<CR>",
		highlight = "AlphaAqua",
	},

	{
		key = "n",
		icon_group = "ui",
		icon = "NewFile",
		label = "New file",
		command = "<cmd>ene | startinsert<CR>",
		highlight = "AlphaGreen",
	},

	{
		key = "p",
		icon_group = "git",
		icon = "Repo",
		label = "Projects",
		command = "<cmd>lua require('yap').project_picker.open(require('yap').config)<CR>",
		highlight = "AlphaPurple",
	},

	{
		key = "r",
		icon_group = "ui",
		icon = "History",
		label = "Recent files",
		command = "<cmd>Telescope oldfiles<CR>",
		highlight = "AlphaYellow",
	},

	{
		key = "t",
		icon_group = "ui",
		icon = "Text",
		label = "Find text",
		command = "<cmd>Telescope live_grep<CR>",
		highlight = "AlphaOrange",
	},

	{
		key = "m",
		icon_group = "ui",
		icon = "BookMark",
		label = "Marks",
		command = "<cmd>Telescope marks<CR>",
		highlight = "AlphaRed",
	},

	{
		key = "c",
		icon_group = "ui",
		icon = "Gear",
		label = "Config",
		command = "<cmd>edit " .. vim.fn.fnameescape(vim.fn.stdpath("config") .. "/init.lua") .. "<CR>",
		highlight = "AlphaTeal",
	},

	{
		key = "l",
		icon_group = "which_key",
		icon = "Plugins",
		label = "Lazy",
		command = "<cmd>Lazy<CR>",
		highlight = "AlphaBlue",
	},

	{
		key = "h",
		icon_group = "ui",
		icon = "Bug",
		label = "Health",
		command = "<cmd>checkhealth<CR>",
		highlight = "AlphaRed",
	},

	{
		key = "q",
		icon_group = "ui",
		icon = "SignOut",
		label = "Quit",
		command = "<cmd>qa<CR>",
		highlight = "AlphaMuted",
	},
}

return M
