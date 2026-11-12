return {
	{
		"nvim-mini/mini.files",
		version = "*",
		dependencies = {
			"nvim-mini/mini.icons",
		},
		keys = {
			{
				"<leader>e",
				function()
					require("mini.files").open(vim.fn.getcwd())
				end,
				desc = "Open Mini.files",
			},
		},
		config = function()
			require("soul.core.helpers.mini.files").setup()
		end,
	},
	{
		"nvim-mini/mini.icons",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("soul.core.helpers.mini.icons").setup()
		end,
	},
	{
		"nvim-mini/mini.pairs",
		version = "*",
		event = "InsertEnter",
		config = function()
			require("soul.core.helpers.mini.pairs").setup()
		end,
	},
	{
		"nvim-mini/mini.ai",
		version = "*",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("soul.core.helpers.mini.ai").setup()
		end,
	},
	{
		"nvim-mini/mini.surround",
		version = "*",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("soul.core.helpers.mini.surround").setup()
		end,
	},
	{
		"nvim-mini/mini.notify",
		version = "*",
		config = function()
			require("soul.core.helpers.mini.notify").setup()
		end,
	},
	{
		"nvim-mini/mini.sessions",
		version = "*",
		config = function()
			require("soul.core.helpers.mini.sessions").setup()
		end,
	}
}
