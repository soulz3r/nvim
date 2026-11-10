local M = {
	"soulz3r/yap.nvim",
	lazy = true,
}

function M.config()
	require("yap.ui").setup({})
	require("yap.c").setup()
end

return M
