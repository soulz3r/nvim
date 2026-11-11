local M = {
	"nvim-mini/mini.pairs",
	version = "*",
	event = "InsertEnter",
}
function M.config()
	require("mini.pairs").setup()
end

return M
