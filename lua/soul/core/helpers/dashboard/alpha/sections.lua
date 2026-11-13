local M = {}

function M.build(dashboard, code_examples)
	code_examples = code_examples ~= false

	local icons = require("soul.core.helpers.icons")
	local utils = require("alpha.utils")
	local logo_data = require("soul.core.helpers.dashboard.logo")
	local logo = logo_data.build()

	---------------------------------------------------------------------------
	-- Header
	---------------------------------------------------------------------------

	local header_data = code_examples and require("soul.core.helpers.dashboard.header") or nil
	local tutorial = code_examples and require("soul.core.helpers.dashboard.alpha.tutorial") or nil
	local static_byte_highlights

	if code_examples then
		local header = vim.deepcopy(header_data.lines)
		local header_highlights = require("soul.core.helpers.dashboard.highlights")
		dashboard.section.header.val = header

		local header_hl = header_highlights.add_character_ranges(
			header,
			header_data.highlights,
			{ "╚", "═", "╝", "╗", "║", "╔" },
			"AlphaTeal"
		)
		static_byte_highlights = utils.charhl_to_bytehl(header_hl, header)

		dashboard.section.header.opts = {
			position = "center",
			hl = static_byte_highlights,
		}
	end
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

		vim.cmd.AlphaRedraw()
	end

	local footer = footer_data.new(set_footer)

	---------------------------------------------------------------------------
	-- Layout
	---------------------------------------------------------------------------

	dashboard.opts.layout = {
		{ type = "padding", val = 1 },

		logo.section,

		{ type = "padding", val = 1 },
	}

	if code_examples then
		table.insert(dashboard.opts.layout, dashboard.section.header)
		table.insert(dashboard.opts.layout, { type = "padding", val = 1 })
	end

	table.insert(dashboard.opts.layout, dashboard.section.buttons)
	table.insert(dashboard.opts.layout, { type = "padding", val = 1 })
	table.insert(dashboard.opts.layout, dashboard.section.footer)

	dashboard.opts.opts = {
		noautocmd = true,
	}

	---------------------------------------------------------------------------
	-- Animation timeline
	---------------------------------------------------------------------------

	local animation_data = code_examples and header_data.animation or { speed = 65 }
	local timeline = code_examples and tutorial.build_animation_timeline(animation_data, logo.width) or {}
	local animation_step = 1

	local function apply_animation_frame()
		if not code_examples then
			return
		end

		local frame = timeline[animation_step]
		local start_line = animation_data.start_line

		for index = 1, 7 do
			dashboard.section.header.val[start_line + index - 1] = frame[index] or ""
		end

		local ranges = vim.deepcopy(static_byte_highlights)

		-- Alpha detects multiline highlights by inspecting the first range.
		-- The first two header rows are intentionally blank, so seed a
		-- zero-width range to keep the following row-indexed ranges nested.
		if not ranges[1] or not ranges[1][1] then
			ranges[1] = { { "Normal", 0, 0 } }
		end

		local animated_ranges = tutorial.build_animation_highlights(frame, start_line)

		-- Animated ranges already use byte offsets, matching Alpha's API.
		for line_number, line_ranges in pairs(animated_ranges) do
			ranges[line_number] = line_ranges
		end

		dashboard.section.header.opts.hl = ranges
	end

	apply_animation_frame()

	return {
		logo = logo,
		footer = footer,
		animation_data = animation_data,
		apply_animation_frame = apply_animation_frame,

		next_animation_frame = function()
			if not code_examples then
				return
			end

			animation_step = animation_step + 1

			if animation_step > #timeline then
				animation_step = 1
			end

			apply_animation_frame()
		end,
	}
end

return M
