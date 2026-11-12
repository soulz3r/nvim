local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
}

function M.config()
	require("soul.config.alpha.init").setup()
end

return M
