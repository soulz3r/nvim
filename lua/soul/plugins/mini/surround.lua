return {
	"nvim-mini/mini.surround",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("mini.surround").setup()
	end,
}
