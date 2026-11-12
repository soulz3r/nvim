local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
}

function M.config()
	require("soul.plugins.alpha.init").setup()
end

return M
