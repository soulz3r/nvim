local M = {
	"nvim-mini/mini.icons",
	version = "*",
	event = "VeryLazy",
}

function M.config()
	require("soul.core.helpers.mini.icons").setup()
end

return M
