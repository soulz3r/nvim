local M = {}

local function build_animation_timeline(animation)
	local timeline = {}
	local chars_per_tick = math.max(1, animation.chars_per_tick or 4)
	local hold_ticks = math.max(0, animation.hold_ticks or 0)

	local function push(lines)
		timeline[#timeline + 1] = vim.deepcopy(lines)
	end

	for _, scene in ipairs(animation.scenes) do
		local visible = { "", "", "", "", "" }

		for line_index, line in ipairs(scene.lines) do
			if line_index == scene.cursor_line then
				local target = math.max(1, scene.cursor_target or 1)

				for column = 1, target, 2 do
					visible[line_index] = string.rep(" ", column - 1) .. "^"
					push(visible)
				end

				visible[line_index] = string.rep(" ", target - 1) .. "^"
				push(visible)
			else
				for column = 1, #line, chars_per_tick do
					visible[line_index] = line:sub(1, math.min(column + chars_per_tick - 1, #line))
					push(visible)
				end

				if line == "" then
					push(visible)
				end
			end
		end

		for _ = 1, hold_ticks do
			push(visible)
		end
	end

	return timeline
end

local function add_range(ranges, group, line_number, _, first, last)
	if first < last then
		ranges[line_number] = ranges[line_number] or {}
		ranges[line_number][#ranges[line_number] + 1] = { group, first, last }
	end
end

local function add_pattern(ranges, group, line_number, line, pattern)
	local first = 1

	while true do
		local start_index, end_index = line:find(pattern, first)
		if not start_index then
			break
		end

		add_range(ranges, group, line_number, line, start_index - 1, end_index)
		first = end_index + 1
	end
end

local function build_animation_highlights(lines, start_line)
	local ranges = {}
	local keywords = {
		["int"] = true,
		["void"] = true,
		["char"] = true,
		["float"] = true,
		["double"] = true,
		["const"] = true,
		["unsigned"] = true,
		["long"] = true,
		["short"] = true,
	}

	for index, line in ipairs(lines) do
		local line_number = start_line + index - 1

		if line:match("^%s+[A-Z ]+$") then
			add_range(ranges, "AlphaTeal", line_number, line, 0, #line)
		elseif line:match("^%s*int%s") then
			add_pattern(ranges, "Type", line_number, line, "%f[%w_]int%f[^%w_]")
			add_pattern(ranges, "Number", line_number, line, "%f[%w_]%d+%f[^%w_]")
			add_pattern(ranges, "Operator", line_number, line, "[*&=;]")
			add_pattern(ranges, "Identifier", line_number, line, "%f[%a_][%a_][%w_]*")
			for word in pairs(keywords) do
				add_pattern(ranges, "Type", line_number, line, "%f[%w_]" .. word .. "%f[^%w_]")
			end
		elseif line:match("^%s*main%.") or line:match("%->") then
			add_pattern(ranges, "Identifier", line_number, line, "[%w_]+")
			add_pattern(ranges, "Operator", line_number, line, "[%.%-]+")
		else
			add_pattern(ranges, "Number", line_number, line, "0x[%da-fA-F]+")
			add_pattern(ranges, "Number", line_number, line, "%f[%d]%d+%f[%D]")
			add_pattern(ranges, "Operator", line_number, line, "[@=*%-]+")
			if #line > 0 and not line:match("^%s*%^") then
				add_range(ranges, "AlphaYellow", line_number, line, 0, #line)
			end
		end

		if line:match("%^") then
			add_pattern(ranges, "Special", line_number, line, "%^")
		end
	end

	return ranges
end

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
	-- Animation timeline
	---------------------------------------------------------------------------

	local animation_data = header_data.animation
	local timeline = build_animation_timeline(animation_data)
	local animation_step = 1

	local function apply_animation_frame()
		local frame = timeline[animation_step]
		local start_line = animation_data.start_line

		for index, line in ipairs(frame) do
			dashboard.section.header.val[start_line + index - 1] = line
		end

		local ranges = vim.deepcopy(header_data.highlights)
		local animated_ranges = build_animation_highlights(frame, start_line)

		for line_number, line_ranges in pairs(animated_ranges) do
			ranges[line_number] = line_ranges
		end

		dashboard.section.header.opts.hl = utils.charhl_to_bytehl(ranges, dashboard.section.header.val)
	end

	apply_animation_frame()

	return {
		footer = footer,
		animation_data = animation_data,
		apply_animation_frame = apply_animation_frame,

		next_animation_frame = function()
			animation_step = animation_step + 1

			if animation_step > #timeline then
				animation_step = 1
			end

			apply_animation_frame()
		end,
	}
end

return M
