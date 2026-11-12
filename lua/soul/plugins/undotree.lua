return {
	"jiaoshijie/undotree",
	opts = {
		window = {
			border = "rounded",
		},
	},
	keys = {
		{
			"<leader>u",
			function()
				require("undotree").toggle()
			end,
			desc = "Toggle Undotree",
		},
	},
}
