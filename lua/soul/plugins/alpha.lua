local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
}

function M.config()
	local dashboard = require("alpha.themes.dashboard")
	local sections = require("soul.core.helpers.dashboard.alpha.sections")
	local animation_helper = require("soul.core.helpers.dashboard.animation")
	local autocmds = require("soul.core.helpers.dashboard.alpha.autocmds")

	local state = sections.build(dashboard)

	require("alpha").setup(dashboard.opts)

	state.animation = animation_helper.new({
		interval = state.animation_data.speed,

		is_active = function()
			return vim.bo.filetype == "alpha"
		end,

		on_tick = function()
			state.next_animation_frame()
		end,

		redraw = function()
			vim.cmd.AlphaRedraw()
		end,
	})

	state.footer.update()
	autocmds.register(state)
end

return M
