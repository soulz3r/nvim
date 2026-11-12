local M = {
	"nvim-mini/mini.surround",
	version = "*",
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("soul.core.helpers.mini.surround").setup()
end

return M
