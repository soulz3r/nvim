local M = {
	"rachartier/tiny-cmdline.nvim",
	event = "VeryLazy",
	cond = vim.fn.has("nvim-0.12") == 1,
}

function M.config()
	vim.o.cmdheight = 0

	-- Enable Neovim's new UI2 system.
	local ui2 = require("vim._core.ui2")
	ui2.enable({
		msg = {
			-- MiniNotify handles passive messages instead of UI2's message area.
			targets = "cmd",
		},
	})

	-- UI2 and MiniNotify both subscribe to msg_show. Disable UI2's renderer
	-- so it cannot duplicate messages in the cmdline or its own float.
	ui2.msg.msg_show = function() end

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
