local M = {
	"nvim-mini/mini.sessions",
	version = "*",
}

function M.config()
	require("soul.core.helpers.mini.sessions").setup()
end

return M
