local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
}

function M.config()
	require("soul.core.helpers.alpha.init").setup()
end

return M
