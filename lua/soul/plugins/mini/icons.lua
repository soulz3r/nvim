local M = {
	"nvim-mini/mini.icons",
	version = "*",
	event = "VeryLazy",
}
function M.config()
	require("mini.icons").setup()
end
return M
