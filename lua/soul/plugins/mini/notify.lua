local M = {
	"nvim-mini/mini.notify",
	version = "*",
}

function M.config()
	require("soul.core.helpers.mini.notify").setup()
end

return M
