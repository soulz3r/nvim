local M = {
	"nvim-mini/mini.pairs",
	version = "*",
	event = "InsertEnter",
}

function M.config()
	require("soul.core.helpers.mini.pairs").setup()
end

return M
