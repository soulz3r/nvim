local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
	cond = function()
		-- Alpha is only useful for an empty startup, not when opening a file,
		-- directory, or stdin-backed editing session.
		return vim.fn.argc() == 0
	end,

	-- Set false to hide the animated C tutorial below the logo.
	code_examples = false,
}

function M.config()
	local dashboard = require("alpha.themes.dashboard")
	local sections = require("soul.core.helpers.dashboard.alpha.sections")
	local animation_helper = require("soul.core.helpers.dashboard.animation")
	local autocmds = require("soul.core.helpers.dashboard.alpha.autocmds")

	local state = sections.build(dashboard, M.code_examples)
	local logo_tick = 0
	local wordmark_tick = 0

	require("alpha").setup(dashboard.opts)

	state.animation = animation_helper.new({
		interval = state.animation_data.speed,

		is_active = function()
			return vim.bo.filetype == "alpha"
		end,

		on_tick = function()
			state.next_animation_frame()

			logo_tick = logo_tick + 1
			if logo_tick % state.logo.tick_divisor == 0 then
				state.logo.next_frame()
			end

			wordmark_tick = wordmark_tick + 1
			if wordmark_tick % state.logo.wordmark_tick_divisor == 0 then
				state.logo.next_wordmark_frame()
			end
		end,

		redraw = function()
			vim.cmd.AlphaRedraw()
		end,
	})

	state.footer.update()
	autocmds.register(state)
	vim.g.cvim_alpha_ready = true
end

return M
