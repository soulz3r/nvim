local M = {
	"rachartier/tiny-cmdline.nvim",
	event = "VeryLazy",
	cond = vim.fn.has("nvim-0.12") == 1,
}

function M.config()
	vim.o.cmdheight = 0

	-- Enable Neovim's new UI2 system
	require("vim._core.ui2").enable({
		msg = {
			-- The mini.notify UI attachment consumes passive messages and
			-- forwards only warnings and errors. Keep UI2 as a fallback target
			-- for interactive/native UI behavior, not a second message popup.
			targets = "cmd",
		},
	})

	local tiny_cmdline = require("tiny-cmdline")

	tiny_cmdline.setup({
		on_reposition = tiny_cmdline.adapters.blink,
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
