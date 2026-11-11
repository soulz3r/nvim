return {
	"nvim-mini/mini.pairs",
	version = "*",
	event = "InsertEnter",
	config = function()
		require("mini.pairs").setup()
	end,
}
