local M = {
	"nvim-mini/mini.ai",
	version = "*",
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("mini.ai").setup()
end

return M
