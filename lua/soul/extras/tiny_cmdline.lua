local M = {
	"rachartier/tiny-cmdline.nvim",
	event = "VeryLazy",
}

function M.config()
	vim.o.cmdheight = 0

	-- Enable Neovim's new UI2 system
	require("vim._core.ui2").enable({})

	require("tiny-cmdline").setup({
		width = {
			value = "60%",
			min = 40,
			max = 100,
		},
		-- Keep search at the bottom (or remove this if you want search centered too)
		native_types = {},
	})
end

return M
