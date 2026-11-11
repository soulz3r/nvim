local function setup(module)
	return function()
		require("soul.core.helpers.mini." .. module).setup()
	end
end

return {
	{
		"nvim-mini/mini.files",
		keys = {
			{
				"<leader>e",
				function()
					require("mini.files").open(vim.fn.getcwd())
				end,
				desc = "Open Mini.files",
			},
		},
		config = setup("files"),
	},
	{
		"nvim-mini/mini.icons",
		event = "VeryLazy",
		config = setup("icons"),
	},
	{
		"nvim-mini/mini.pairs",
		event = "InsertEnter",
		config = setup("pairs"),
	},
	{
		"nvim-mini/mini.ai",
		event = { "BufReadPost", "BufNewFile" },
		config = setup("ai"),
	},
	{
		"nvim-mini/mini.surround",
		event = { "BufReadPost", "BufNewFile" },
		config = setup("surround"),
	},
	{
		"nvim-mini/mini.notify",
		config = setup("notify"),
	},
	{
		"nvim-mini/mini.sessions",
		config = setup("sessions"),
	},
}
