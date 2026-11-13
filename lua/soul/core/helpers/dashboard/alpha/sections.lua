local M = {}

local function build_animation_timeline(animation, content_width)
	local timeline = {}
	local hold_ticks = math.max(0, animation.hold_ticks or 0)

	local function push(lines)
		timeline[#timeline + 1] = vim.deepcopy(lines)
	end

	for _, scene in ipairs(animation.scenes) do
		-- Every scene uses the same seven-row layout:
		-- heading, two code lines, caret, optional closing line,
		-- separator, explanation.
		local visible = { "", "", "", "", "", "", "" }
		local cursor_source_line = scene.cursor_source_line or 3
		local code_line = scene.lines[cursor_source_line] or ""
		local target = scene.cursor_token and code_line:find(scene.cursor_token, 1, true)

		assert(target, ("dashboard caret token %q was not found in: %s"):format(
			tostring(scene.cursor_token),
			code_line
		))

		local block_width = 0
		for line_index = 1, 3 do
			block_width = math.max(
				block_width,
				vim.fn.strdisplaywidth(scene.lines[line_index] or "")
			)
		end
		if scene.extra_line then
			block_width = math.max(block_width, vim.fn.strdisplaywidth(scene.extra_line))
		end

		local padding = math.max(0, math.floor((content_width - block_width) / 2))
		local indent = string.rep(" ", padding)

		local heading = scene.lines[1] or ""
		for column = 1, #heading do
			visible[1] = indent .. heading:sub(1, column)
			push(visible)
		end

		for line_index = 2, 3 do
			local line = scene.lines[line_index] or ""

			if line_index == cursor_source_line and not scene.extra_line then
				visible[4] = indent .. "^"
				push(visible)
			end

			for column = 1, #line do
				visible[line_index] = indent .. line:sub(1, column)

				if line_index == cursor_source_line and not scene.extra_line then
					local caret_offset = math.min(column, target - 1)
					local caret_column = padding
						+ vim.fn.strdisplaywidth(line:sub(1, caret_offset))
					visible[4] = string.rep(" ", caret_column) .. "^"
				end

				push(visible)
			end
		end

		if scene.extra_line then
			for column = 1, #scene.extra_line do
				visible[5] = indent .. scene.extra_line:sub(1, column)
				push(visible)
			end

			-- Keep the caret hidden until the closing line has finished typing.
			local caret_column = padding
				+ vim.fn.strdisplaywidth(code_line:sub(1, target - 1))
			visible[4] = string.rep(" ", caret_column) .. "^"
			push(visible)
		end

		visible[6] = indent .. (scene.lines[5] or "")
		push(visible)

		local explanation = scene.lines[6] or ""
		local explanation_padding = math.max(
			0,
			math.floor((content_width - vim.fn.strdisplaywidth(explanation)) / 2)
		)
		local explanation_indent = string.rep(" ", explanation_padding)

		for column = 1, #explanation do
			visible[7] = explanation_indent .. explanation:sub(1, column)
			push(visible)
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
	["FIRST PROGRAM"] = "AlphaTopicCompilation",
	COMPILATION = "AlphaTopicCompilation",
	OUTPUT = "AlphaTopicRepresentations",
	TYPES = "AlphaTopicRepresentations",
	CONSTANTS = "AlphaTopicMemory",
	OPERATORS = "AlphaTopicMemory",
	["CONTROL FLOW"] = "AlphaTopicMemory",
	FUNCTIONS = "AlphaTopicMemory",
	ARRAYS = "AlphaTopicDereference",
	STRINGS = "AlphaTopicDereference",
	STRUCTURES = "AlphaTopicDereference",
	POINTERS = "AlphaTopicPointers",
	DEREFERENCE = "AlphaTopicPointers",
	MEMORY = "AlphaTopicPointers",
	PREPROCESSOR = "AlphaTopicMemory",
	MACROS = "AlphaTopicDereference",
	["DYNAMIC MEMORY"] = "AlphaTopicPointers",
	["FILE I O"] = "AlphaTopicDereference",
	BITWISE = "AlphaTopicPointers",
}

local c_types = {
	int = true, char = true, float = true, double = true, void = true,
	short = true, long = true, signed = true, unsigned = true, const = true,
	size_t = true, FILE = true, bool = true, Point = true,
}

local c_keywords = {
	["return"] = true, ["if"] = true, ["else"] = true, ["for"] = true,
	["while"] = true, ["do"] = true, ["switch"] = true, ["case"] = true,
	["break"] = true, ["continue"] = true, ["struct"] = true, ["union"] = true,
	["enum"] = true, ["typedef"] = true, ["sizeof"] = true, ["goto"] = true,
	["default"] = true,
}

local c_storage = {
	static = true, extern = true, register = true, auto = true, _Thread_local = true,
}

local c_constants = {
	["true"] = true, ["false"] = true, NULL = true, nullptr = true, MAX = true,
}

-- Function names used by the tutorial. Recognizing their prefixes lets the
-- function color appear while the identifier is still being typed.
local c_functions = {
	main = true, puts = true, add = true, malloc = true,
	free = true, fopen = true, fclose = true,
}

local function has_prefix(tokens, word)
	for token in pairs(tokens) do
		if token:sub(1, #word) == word then
			return true
		end
	end

	return false
end

local partial_token_groups = {
	{ tokens = c_types, group = "AlphaCodeType" },
	{ tokens = c_keywords, group = "AlphaCodeKeyword" },
	{ tokens = c_storage, group = "AlphaCodeStorage" },
	{ tokens = c_constants, group = "AlphaCodeConstant" },
	{ tokens = c_functions, group = "AlphaCodeFunction" },
}

local function partial_token_group(word)
	local matched_group

	for _, candidate in ipairs(partial_token_groups) do
		if has_prefix(candidate.tokens, word) then
			if matched_group and matched_group ~= candidate.group then
				return nil
			end
			matched_group = candidate.group
		end
	end

	return matched_group
end

local function highlight_c_code(ranges, line_number, line)
	add_range(ranges, "AlphaCodeText", line_number, 0, #line)

	local index = 1
	while index <= #line do
		local char = line:sub(index, index)
		local pair = line:sub(index, index + 1)

		if pair == "//" then
			add_range(ranges, "AlphaCodeComment", line_number, index - 1, #line)
			break
		elseif pair == "/*" then
			local finish = line:find("*/", index + 2, true)
			add_range(ranges, "AlphaCodeComment", line_number, index - 1, finish and finish + 1 or #line)
			break
		elseif char == '"' or char == "'" then
			local finish = index + 1
			while finish <= #line do
				if line:sub(finish, finish) == "\\" then
					finish = finish + 2
				elseif line:sub(finish, finish) == char then
					finish = finish + 1
					break
				else
					finish = finish + 1
				end
			end
			add_range(ranges, "AlphaCodeString", line_number, index - 1, math.min(finish - 1, #line))
			index = finish
		elseif char:match("[%a_]") then
			local finish = line:find("[^%w_]", index) or (#line + 1)
			local word = line:sub(index, finish - 1)
			local next_char = line:sub(finish):match("^%s*(.)")
			local partial = finish > #line
			local is_macro = word:match("^[A-Z_][A-Z%d_]*$") and (not partial or #word >= 2)
			local group = c_types[word] and "AlphaCodeType"
				or c_keywords[word] and "AlphaCodeKeyword"
				or c_storage[word] and "AlphaCodeStorage"
				or c_constants[word] and "AlphaCodeConstant"
				or is_macro and "AlphaCodeMacro"
				or next_char == "(" and "AlphaCodeFunction"
				or partial and partial_token_group(word)
				or "AlphaCodeIdentifier"
			add_range(ranges, group, line_number, index - 1, finish - 1)
			index = finish
		elseif char:match("%d") then
			local number = line:sub(index):match("^0[xX][%da-fA-F]+[uUlL]*")
				or line:sub(index):match("^0[bB][01]+[uUlL]*")
				or line:sub(index):match("^%d+%.?%d*[eE]?[+-]?%d*[fFlLuU]*")
				or line:sub(index):match("^%d+")
			local finish = index + #number
			add_range(ranges, "AlphaCodeNumber", line_number, index - 1, finish - 1)
			index = finish
		elseif char == "#" and line:sub(1, index - 1):match("^%s*$") then
			add_range(ranges, "AlphaCodePreprocessor", line_number, index - 1, index)
			local directive_start, directive_end = line:find("[%a_]+", index + 1)
			if directive_start then
				add_range(ranges, "AlphaCodePreprocessor", line_number, directive_start - 1, directive_end)
				index = directive_end + 1
			else
				index = index + 1
			end
		elseif char:match("[*&=+%-%/%<>!|%%~^]") then
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

local function highlight_preprocessor(ranges, line_number, line)
	highlight_c_code(ranges, line_number, line)
	local directive_start, directive_end = line:find("#%s*[%a_]+")
	if directive_start then
		add_range(ranges, "AlphaCodePreprocessor", line_number, directive_start - 1, directive_end)
	end

	local _, define_end = line:find("#%s*define%s+")
	if define_end then
		local name_start, name_end = line:find("[%a_][%w_]*", define_end + 1)
		if name_start then
			add_range(ranges, "AlphaCodeMacro", line_number, name_start - 1, name_end)
		end
	end

	local include_start, include_end = line:find("<[^>]+>")
	if include_start then
		add_range(ranges, "AlphaCodeString", line_number, include_start - 1, include_end)
	end
end

-- Keep grammatical glue neutral and highlight every meaningful word.
-- This avoids a hand-maintained vocabulary that inevitably misses new copy.
local explanation_stopwords = {
	a = true, an = true, and = true, are = true, as = true, at = true,
	by = true, for = true, from = true,
	in = true, into = true, is = true, it = true, its = true, of = true,
	on = true, or = true, the = true, their = true,
	then = true, this = true, to = true, when = true, with = true,
}

local function is_stopword_prefix(word)
	for stopword in pairs(explanation_stopwords) do
		if stopword:sub(1, #word) == word then
			return true
		end
	end

	return false
end

local function highlight_message(ranges, line_number, line)
	if #line == 0 then
		return
	end

	add_range(ranges, "AlphaMessage", line_number, 0, #line)

	for first, word in line:gmatch("()([%a_]+)") do
		local last = first + #word - 1
		local is_final_word = line:sub(last + 1):match("^%s*[%p]*$") ~= nil
		local should_highlight = false

		if is_final_word then
			-- Do not color ambiguous prefixes such as "t" while they may
			-- still become grammatical glue like "the" or "to".
			should_highlight = #word > 1
				and not explanation_stopwords[word]
				and not is_stopword_prefix(word)
		else
			should_highlight = not explanation_stopwords[word]
		end

		if should_highlight then
			add_range(ranges, "AlphaMessageKey", line_number, first - 1, last)
		end
	end

	for _, term in ipairs({ "&value", "*ptr", "+=" }) do
		local first = 1
		while true do
			local start_index, end_index = line:find(term, first, true)
			if not start_index then
				break
			end
			add_range(ranges, "AlphaMessageKey", line_number, start_index - 1, end_index)
			first = end_index + 1
		end

		for length = 1, #term - 1 do
			local prefix = term:sub(1, length)
			if line:sub(-length) == prefix then
				add_range(ranges, "AlphaMessageKey", line_number, #line - length, #line)
			end
		end
	end
end

local function highlight_animation_line(ranges, line_number, line, line_index)
	local heading = line:match("^%s*(.-)%s*$")
	local topic_group = topic_highlights[heading]

	-- A partial heading can match several topics. Only apply a color while
	-- every matching topic agrees, avoiding arbitrary color changes from pairs().
	if not topic_group and #heading > 0 and heading:match("^[A-Z ]+$") then
		local candidate_group
		local ambiguous = false

		for title, group in pairs(topic_highlights) do
			if title:sub(1, #heading) == heading then
				if candidate_group and candidate_group ~= group then
					ambiguous = true
					break
				end
				candidate_group = group
			end
		end

		if not ambiguous then
			topic_group = candidate_group
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

	if line:match("^%s*#") then
		highlight_preprocessor(ranges, line_number, line)
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

	if line_index == 2 or line_index == 3 or line_index == 5 then
		highlight_c_code(ranges, line_number, line)
		return
	end

	if line:match("^%s*%-+%s*$") then
		add_range(ranges, "AlphaCodeSeparator", line_number, 0, #line)
		return
	end

	if line_index == 7 then
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
	local logo_width = 0
	for index = 1, 6 do
		logo_width = math.max(
			logo_width,
			vim.fn.strdisplaywidth(header_data.lines[index] or "")
		)
	end

	local timeline = build_animation_timeline(animation_data, logo_width)
	local animation_step = 1

	local function apply_animation_frame()
		local frame = timeline[animation_step]
		local start_line = animation_data.start_line

		for index = 1, 7 do
			dashboard.section.header.val[start_line + index - 1] = frame[index] or ""
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
