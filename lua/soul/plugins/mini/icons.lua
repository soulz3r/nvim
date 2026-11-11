return {
	"nvim-mini/mini.icons",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("mini.icons").setup()
	end,
}
