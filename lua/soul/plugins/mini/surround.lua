return {
	"nvim-mini/mini.surround",
	version = "*",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("mini.surround").setup()
	end,
}
