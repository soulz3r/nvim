local M = {}

function M.build(dashboard)
	local icons = require("soul.core.helpers.icons")
	local utils = require("alpha.utils")

	--------------------------------------------------------------------------- 
	-- Header
	---------------------------------------------------------------------------

	local header_data = require("soul.core.helpers.dashboard.header")
	local header = vim.deepcopy(header_data.lines)
	local header_highlights = require("soul.core.helpers.dashboard.highlights")

	dashboard.section.header.val = header

	local header_hl = header_highlights.add_character_ranges(
		header,
		header_data.highlights,
		{ "╚", "═", "╝", "╗", "║", "╔" },
		"AlphaTeal"
	)

	dashboard.section.header.opts = {
		position = "center",
		hl = utils.charhl_to_bytehl(header_hl, header),
	}

	--------------------------------------------------------------------------- 
	-- Buttons
	---------------------------------------------------------------------------

	local button_data = require("soul.core.helpers.dashboard.buttons")

	local function create_button(item)
		local icon = icons[item.icon_group][item.icon]
		local button = dashboard.button(item.key, icon .. " " .. item.label, item.command)

		button.opts.hl_shortcut = "Include"
		button.opts.hl = {
			{
				item.highlight,
				0,
				#icon,
			},
		}

		return button
	end

	dashboard.section.buttons.val = vim.tbl_map(create_button, button_data.items)
	dashboard.section.buttons.opts.hl = "Include"

	--------------------------------------------------------------------------- 
	-- Footer
	---------------------------------------------------------------------------

	local footer_data = require("soul.core.helpers.dashboard.footer")

	dashboard.section.footer = {
		type = "group",

		val = {
			{
				type = "text",
				val = "",
			},

			{
				type = "text",
				val = "",
				opts = {
					position = "center",
				},
			},

			{
				type = "text",
				val = "",
				opts = {
					position = "center",
				},
			},

			{
				type = "text",
				val = "",
				opts = {
					position = "center",
				},
			},
		},

		opts = {
			spacing = 0,
		},
	}

	local function set_footer(lines)
		for index, line in ipairs(lines) do
			dashboard.section.footer.val[index].val = line
		end

		pcall(vim.cmd.AlphaRedraw)
	end

	local footer = footer_data.new(set_footer)

	--------------------------------------------------------------------------- 
	-- Layout
	---------------------------------------------------------------------------

	dashboard.opts.layout = {
		{ type = "padding", val = 1 },

		dashboard.section.header,

		{ type = "padding", val = 1 },

		dashboard.section.buttons,

		{ type = "padding", val = 1 },

		dashboard.section.footer,
	}

	dashboard.opts.opts = {
		noautocmd = true,
	}

	--------------------------------------------------------------------------- 
	-- Animation frame state
	---------------------------------------------------------------------------

	local animation_data = header_data.animation
	local animation_step = 1

	local function apply_animation_frame()
		local frame = animation_data.frames[animation_step]
		local start_line = animation_data.start_line

		for index, line in ipairs(frame) do
			dashboard.section.header.val[start_line + index - 1] = line
		end
	end

	apply_animation_frame()

	return {
		footer = footer,
		animation_data = animation_data,
		apply_animation_frame = apply_animation_frame,

		next_animation_frame = function()
			animation_step = animation_step + 1

			if animation_step > #animation_data.frames then
				animation_step = 1
			end

			apply_animation_frame()
		end,
	}
end

return M
