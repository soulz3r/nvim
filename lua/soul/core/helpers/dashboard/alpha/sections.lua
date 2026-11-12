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

local function add_range(ranges, group, line_number, first, last)
	if first < last then
		ranges[line_number] = ranges[line_number] or {}
		ranges[line_number][#ranges[line_number] + 1] = { group, first, last }
	end
end

local topic_highlights = {
	POINTERS = "AlphaTopicPointers",
	DEREFERENCE = "AlphaTopicDereference",
	["MEMORY MAP"] = "AlphaTopicMemory",
	COMPILATION = "AlphaTopicCompilation",
	REPRESENTATIONS = "AlphaTopicRepresentations",
}

local c_types = {
	int = true, char = true, float = true, double = true, void = true,
	short = true, long = true, signed = true, unsigned = true, const = true,
	size_t = true,
}

local c_keywords = {
	["return"] = true, ["if"] = true, ["else"] = true, ["for"] = true,
	["while"] = true, ["struct"] = true, ["enum"] = true, ["typedef"] = true,
	["static"] = true, ["extern"] = true, ["sizeof"] = true,
}

local function highlight_c_code(ranges, line_number, line)
	add_range(ranges, "AlphaCodeText", line_number, 0, #line)

	local index = 1
	while index <= #line do
		local char = line:sub(index, index)

		if char:match("[%a_]") then
			local finish = line:find("[^%w_]", index) or (#line + 1)
			local word = line:sub(index, finish - 1)
			local group = c_types[word] and "AlphaCodeType"
				or c_keywords[word] and "AlphaCodeKeyword"
				or "AlphaCodeIdentifier"
			add_range(ranges, group, line_number, index - 1, finish - 1)
			index = finish
		elseif char:match("%d") then
			local number = line:sub(index):match("^0[xX][%da-fA-F]+")
				or line:sub(index):match("^%d+")
			local finish = index + #number
			add_range(ranges, "AlphaCodeNumber", line_number, index - 1, finish - 1)
			index = finish
		elseif char:match("[*&=+%-%/%<>!|%%]") then
			local finish = index + 1
			while finish <= #line and line:sub(finish, finish):match("[=&|<>]") do
				finish = finish + 1
			end
			add_range(ranges, "AlphaCodeOperator", line_number, index - 1, finish - 1)
			index = finish
		elseif char:match("[;:,%.%(%)%[%]{}]") then
			add_range(ranges, "AlphaCodePunctuation", line_number, index - 1, index)
			index = index + 1
		else
			index = index + 1
		end
	end
end

local function highlight_message(ranges, line_number, line)
	if #line == 0 then
		return
	end

	add_range(ranges, "AlphaMessage", line_number, 0, #line)

	for _, term in ipairs({ "&value", "*ptr", "address", "stored value", "pointer", "same value" }) do
		local first = 1
		while true do
			local start_index, end_index = line:find(term, first, true)
			if not start_index then
				break
			end
			add_range(ranges, "AlphaMessageKey", line_number, start_index - 1, end_index)
			first = end_index + 1
		end
	end
end

local function highlight_animation_line(ranges, line_number, line, line_index)
	local heading = line:match("^%s*(.-)%s*$")
	local topic_group = topic_highlights[heading]

	-- Keep the topic color while its title is still being typed.
	if not topic_group and heading:match("^[A-Z ]+$") then
		for title, group in pairs(topic_highlights) do
			if title:sub(1, #heading) == heading then
				topic_group = group
				break
			end
		end
	end

	if topic_group then
		add_range(ranges, topic_group, line_number, 0, #line)
		return
	end

	if line:match("^%s*%^") then
		local caret = line:find("%^")
		add_range(ranges, "AlphaCodeCursor", line_number, caret - 1, caret)
		return
	end

	if line:match("^%s*int%s") then
		highlight_c_code(ranges, line_number, line)
		return
	end

	if line:match("^%s*main%.[ciso]+") or line:match("%->%s*cvim") then
		add_range(ranges, "AlphaCodeFile", line_number, 0, #line)
		local arrow = line:find("%-%>")
		if arrow then
			add_range(ranges, "AlphaCodeOperator", line_number, arrow - 1, arrow + 1)
			local target = line:find("cvim", arrow, true)
			if target then
				add_range(ranges, "AlphaCodeStage", line_number, target - 1, target + 3)
			end
		end
		return
	end

	-- Representation labels and values use the same role colors regardless
	-- of whether the value is decimal, hexadecimal, or binary.
	if line:find("decimal", 1, true)
		or line:find("hexadecimal", 1, true)
		or line:find("binary", 1, true)
	then
		add_range(ranges, "AlphaCodeText", line_number, 0, #line)

		local label_start, label_end = line:find("%a+")
		if label_start then
			add_range(ranges, "AlphaCodeStage", line_number, label_start - 1, label_end)
		end

		local value_start, value_end = line:find("0x[%da-fA-F]+")
		if not value_start then
			value_start, value_end = line:find("%f[%d]%d+%f[%D]")
		end
		if value_start then
			add_range(ranges, "AlphaCodeNumber", line_number, value_start - 1, value_end)
		end
		return
	end

	if line:find("0x", 1, true) or line:find("@", 1, true) then
		add_range(ranges, "AlphaCodeText", line_number, 0, #line)

		for _, identifier in ipairs({ "value", "ptr" }) do
			local first = 1
			while true do
				local identifier_start, identifier_end = line:find(identifier, first, true)
				if not identifier_start then
					break
				end
				add_range(
					ranges,
					"AlphaCodeIdentifier",
					line_number,
					identifier_start - 1,
					identifier_end
				)
				first = identifier_end + 1
			end
		end

		local first = 1
		while true do
			local number_start, number_end = line:find("0x[%da-fA-F]+", first)
			if not number_start then
				break
			end
			add_range(ranges, "AlphaCodeNumber", line_number, number_start - 1, number_end)
			first = number_end + 1
		end

		local number_start, number_end = line:find("%f[%d]%d+%f[%D]")
		if number_start then
			add_range(ranges, "AlphaCodeNumber", line_number, number_start - 1, number_end)
		end

		local operator_search = 1
		while true do
			local operator_start, operator_end = line:find("[@=*%-]+", operator_search)
			if not operator_start then
				break
			end
			add_range(ranges, "AlphaCodeOperator", line_number, operator_start - 1, operator_end)
			operator_search = operator_end + 1
		end

		local arrow_search = 1
		while true do
			local arrow_start, arrow_end = line:find("%-%>", arrow_search)
			if not arrow_start then
				break
			end
			add_range(ranges, "AlphaCodeOperator", line_number, arrow_start - 1, arrow_end)
			arrow_search = arrow_end + 1
		end
		return
	end

	if line_index == 5 then
		highlight_message(ranges, line_number, line)
	end
end

local function build_animation_highlights(lines, start_line)
	local ranges = {}
	for index, line in ipairs(lines) do
		highlight_animation_line(ranges, start_line + index - 1, line, index)
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

		-- Alpha expects a contiguous per-line highlight table. Keep the blank
		-- tagline separator (line 8) so ipairs does not stop before the animation.
		for line_number = 1, start_line - 1 do
			ranges[line_number] = ranges[line_number] or {}
		end

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
