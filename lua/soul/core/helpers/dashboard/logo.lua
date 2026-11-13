local M = {}

local WIDTH = 66
local HEIGHT = 15
local C_WIDTH = 25
local C_HEIGHT = 13
local CENTER_X = 11
local CENTER_Y = 7
local ROTATION_FRAMES = 72
local ART_START = 25
local ART_TOP = 3
local TAGLINE = "C, with a better editor."
local TAGLINE_WIDTH = vim.fn.strdisplaywidth(TAGLINE)
local TAGLINE_START = math.floor((WIDTH - TAGLINE_WIDTH) / 2) + 1
local TAGLINE_RULE_START = math.floor((WIDTH - TAGLINE_WIDTH) / 2) + 1
local TAGLINE_RULE = require("soul.core.helpers.dashboard.horizontal_rule").build(TAGLINE_WIDTH)

local WORDMARK = {
	"               ▄▄▄                 ",
	" ▄▒▓▄   ▄▄▄   ▄▓▒▓▒▀  ▓▒▓▒▄▄         ",
	" ▒░▒░▌ ▐▒▓▒▓  ▒░▒░   ▒░▒░▓▒▄▄▄▒▄▄   ",
	" ░░░░   ░▒░█▌ ░█░█   ░█░▄ ▀▒▓▒░▒░░▄ ",
	" ▐░█░▌  ░████ ▓████░ ▓░░██  ░▒ ▀░██░▌",
	"░▒███▓ ▐██░█▌ ▓░░██  ▓███░▓ ▀░  ▓░░██",
	"   ███▄████▀  ▐██░░▓ ░████      ████",
	"    ▀▀██▀▀    ████▌  ░███▀       ▀███",
	"",
}

local glyphs = { ".", ":", "-", "=", "+", "*", "#", "%", "@" }
local GLITCH_BLOCKS = { "░", "▒", "▓", "█" }
local GLITCH_COLORS = {
	"CvimGlitchPink",
	"CvimGlitchRed",
	"CvimGlitchOrange",
	"CvimGlitchYellow",
	"CvimGlitchGreen",
	"CvimGlitchCyan",
	"CvimGlitchBlue",
	"CvimGlitchPurple",
}

local GLITCH_PALETTE = {
	CvimGlitchPink = "#ff3bd4",
	CvimGlitchRed = "#ff365e",
	CvimGlitchOrange = "#ff8a24",
	CvimGlitchYellow = "#f9f871",
	CvimGlitchGreen = "#a8ff3e",
	CvimGlitchCyan = "#28f0e5",
	CvimGlitchBlue = "#438bff",
	CvimGlitchPurple = "#b56bff",
}

local function setup_glitch_highlights()
	for group, color in pairs(GLITCH_PALETTE) do
		vim.api.nvim_set_hl(0, group, { fg = color, bold = true })
	end
end

local function split_chars(value)
	local chars = {}
	local count = vim.fn.strchars(value)

	for index = 0, count - 1 do
		chars[#chars + 1] = vim.fn.strcharpart(value, index, 1)
	end

	return chars
end

local WORDMARK_CHARS = {}
for row, line in ipairs(WORDMARK) do
	WORDMARK_CHARS[row] = split_chars(line)
end

local function create_grid(width, height, value)
	local grid = {}
	for y = 1, height do
		grid[y] = {}
		for x = 1, width do
			grid[y][x] = value
		end
	end
	return grid
end

local function wordmark_group(char)
	if char == "█" or char == "▓" then
		return "AlphaTeal"
	elseif char == "▒" or char == "▄" or char == "▀" or char == "▐" or char == "▌" then
		return "AlphaAqua"
	elseif char == "░" then
		return "AlphaGreen"
	end

	return "AlphaYellow"
end

-- Stable pseudo-random values make each glitch phase look irregular without
-- changing the artwork every time the rotating C redraws.
local function glitch_noise(row, column, phase, salt)
	local value = (row * 73856093 + column * 19349663 + phase * 83492791 + salt * 49979687)
	return (value * 48271) % 2147483647
end

local function render_frame(frame, glitch_state)
	local rotation = (frame - 1) * (2 * math.pi / ROTATION_FRAMES)
	local cosine = math.cos(rotation)
	local sine = math.sin(rotation)

	local depth = create_grid(C_WIDTH, C_HEIGHT, -math.huge)
	local pixels = create_grid(C_WIDTH, C_HEIGHT, " ")
	local groups = create_grid(C_WIDTH, C_HEIGHT, nil)

	local light_x, light_y, light_z = -0.35, 0.55, 0.76
	local light_length = math.sqrt(light_x ^ 2 + light_y ^ 2 + light_z ^ 2)
	light_x = light_x / light_length
	light_y = light_y / light_length
	light_z = light_z / light_length

	-- A C-shaped tube, sampled as a 3D surface and projected into terminal cells.
	for theta_step = 0, 144 do
		local theta = math.rad(48 + theta_step * (264 / 144))
		local theta_cos = math.cos(theta)
		local theta_sin = math.sin(theta)

		for phi_step = 0, 63 do
			local phi = phi_step * (2 * math.pi / 64)
			local phi_cos = math.cos(phi)
			local phi_sin = math.sin(phi)

			local radius = 1 + 0.23 * phi_cos
			local x = radius * theta_cos
			local y = radius * theta_sin
			local z = 0.23 * phi_sin

			local projected_x = x * cosine + z * sine
			local projected_z = -x * sine + z * cosine

			local column = math.floor(CENTER_X + projected_x * 9 + 0.5)
			local row = math.floor(CENTER_Y - y * 5 + 0.5)

			if
				column >= 1
				and column <= C_WIDTH
				and row >= 1
				and row <= C_HEIGHT
				and projected_z > depth[row][column]
			then
				depth[row][column] = projected_z

				local normal_x = phi_cos * theta_cos
				local normal_y = phi_cos * theta_sin
				local normal_z = phi_sin
				local rotated_normal_x = normal_x * cosine + normal_z * sine
				local rotated_normal_z = -normal_x * sine + normal_z * cosine

				local diffuse =
					math.max(0, rotated_normal_x * light_x + normal_y * light_y + rotated_normal_z * light_z)
				local shade = 0.2 + diffuse * 0.8
				local glyph_index = math.floor(shade * (#glyphs - 1)) + 1

				pixels[row][column] = glyphs[glyph_index]
				groups[row][column] = shade > 0.72 and "AlphaAqua" or shade > 0.46 and "AlphaTeal" or "AlphaGreen"
			end
		end
	end

	-- Glitch events are selected by the animation state machine, not a fixed
	-- repeating frame cycle.
	local tearing = glitch_state.tearing
	local chromatic = glitch_state.chromatic
	local block_noise = glitch_state.block_noise
	local scanline = glitch_state.scanline
	local burst = glitch_state.burst
	local interference = glitch_state.interference
	local glitch_seed = glitch_state.seed
	local lines = {}
	local ranges = {}

	for row = 1, HEIGHT do
		local cells = {}
		local cell_groups = {}
		local art_row = row - ART_TOP + 1
		local art_chars = WORDMARK_CHARS[art_row]

		-- Tear a randomly sized fragment at a random position. The rest of
		-- every line stays exactly where the ASCII artwork placed it.
		local tear_noise = glitch_noise(art_row, 1, glitch_seed, 1)
		local tear_start = 1 + (tear_noise % 24)
		local tear_end = tear_start + 5 + (math.floor(tear_noise / 29) % 13)
		local tear_shift = (math.floor(tear_noise / 113) % 13) - 6
		local burst_row = glitch_seed % #WORDMARK_CHARS + 1
		local burst_start = 1 + (math.floor(glitch_seed / 17) % 20)
		local burst_end = burst_start + 9 + (math.floor(glitch_seed / 43) % 16)
		local burst_shift = (math.floor(glitch_seed / 97) % 19) - 9
		local row_shift = tearing and tear_shift or 0
		if burst and art_row == burst_row then
			row_shift = burst_shift
		end

		for column = 1, WIDTH do
			local char = " "
			local group

			if column <= C_WIDTH and row <= C_HEIGHT then
				char = pixels[row][column]
				group = groups[row][column]
			end

			local art_column = column - ART_START + 1
			if art_chars and art_column >= 1 and art_column <= #art_chars then
				local source_column = art_column - row_shift
				local in_burst = burst and art_row == burst_row
					and art_column >= burst_start and art_column <= burst_end
				local in_tear = tearing and art_column >= tear_start and art_column <= tear_end
				char = art_chars[source_column] or " "
				group = char ~= " " and wordmark_group(char) or nil
				local noise = glitch_noise(art_row, art_column, glitch_seed, 2)
				if (in_tear or in_burst) and char ~= " " then
					group = GLITCH_COLORS[noise % #GLITCH_COLORS + 1]
				end

				-- Dense digital corruption: replace glyphs and empty cells with
				-- bright block fragments instead of merely recoloring the logo.
				if (block_noise or in_burst or interference) and noise % (in_burst and 3 or 7) < (in_burst and 2 or 2) then
					char = GLITCH_BLOCKS[math.floor(noise / 17) % #GLITCH_BLOCKS + 1]
					group = GLITCH_COLORS[math.floor(noise / 71) % #GLITCH_COLORS + 1]
				end
			end

			cells[column] = char
			cell_groups[column] = group
		end

		-- Add a sparse one-cell color ghost beside the original glyph.
		-- The original character remains intact, keeping the wordmark readable.
		if chromatic and art_chars and #art_chars > 0 then
			for art_column = 1, #art_chars do
				local source = art_chars[art_column]
				local noise = glitch_noise(art_row, art_column, glitch_seed, 3)
				if source ~= " " and noise % 5 < 2 then
					local ghost_offset = (math.floor(noise / 13) % 5) - 2
					if ghost_offset == 0 then
						ghost_offset = art_row % 2 == 0 and 1 or -1
					end
					local target = ART_START + art_column - 1 + ghost_offset
					if target >= ART_START and target <= WIDTH then
						cells[target] = source
						cell_groups[target] = GLITCH_COLORS[noise % #GLITCH_COLORS + 1]
					end
				end
			end
		end

		-- Bright scanline bands cut through the wordmark for a few frames.
		if scanline and art_chars and #art_chars > 0 and glitch_noise(art_row, 1, glitch_seed, 5) % 3 == 0 then
			for column = ART_START, math.min(WIDTH, ART_START + #art_chars - 1) do
				local noise = glitch_noise(art_row, column - ART_START + 1, glitch_seed, 5)
				if noise % 4 == 0 then
					cells[column] = GLITCH_BLOCKS[math.floor(noise / 17) % #GLITCH_BLOCKS + 1]
				end
				cell_groups[column] = GLITCH_COLORS[noise % #GLITCH_COLORS + 1]
			end
		end

		if row == HEIGHT - 1 then
			for column = 1, vim.fn.strchars(TAGLINE) do
				local target = TAGLINE_START + column - 1
				cells[target] = vim.fn.strcharpart(TAGLINE, column - 1, 1)
				cell_groups[target] = "AlphaYellow"
			end
		elseif row == HEIGHT then
			for column = 1, vim.fn.strchars(TAGLINE_RULE) do
				local target = TAGLINE_RULE_START + column - 1
				cells[target] = vim.fn.strcharpart(TAGLINE_RULE, column - 1, 1)
				cell_groups[target] = "AlphaTeal"
			end
		end

		local line_ranges = {}
		local active_group
		local range_start

		for column = 1, WIDTH + 1 do
			local group = column <= WIDTH and cell_groups[column] or nil

			if group ~= active_group then
				if active_group then
					line_ranges[#line_ranges + 1] = {
						active_group,
						range_start - 1,
						column - 1,
					}
				end

				active_group = group
				range_start = group and column or nil
			end
		end

		lines[row] = table.concat(cells)

		-- Alpha detects multiline highlights from the first row's first range.
		-- Keep the nested highlight shape valid even when the top row is blank.
		if row == 1 and #line_ranges == 0 then
			line_ranges[1] = { "Normal", 0, 0 }
		end

		ranges[row] = line_ranges
	end

	return lines, ranges
end

function M.build()
	local utils = require("alpha.utils")
	setup_glitch_highlights()
	local section = {
		type = "text",
		val = {},
		opts = {
			position = "center",
			hl = {},
		},
	}

	local rotation_frame = 1
	local random_state = math.floor(
		(vim.uv and vim.uv.hrtime and vim.uv.hrtime() or os.time()) % 2147483646
	) + 1
	local function random_int(maximum)
		random_state = (random_state * 48271) % 2147483647
		return (random_state % maximum) + 1
	end

	local glitch_state = {
		tearing = false,
		chromatic = false,
		block_noise = false,
		scanline = false,
		burst = false,
		interference = false,
		seed = random_int(2147483646),
	}
	local glitch_remaining = 0
	local glitch_cooldown = 0

	local function apply_frame()
		local lines, character_ranges = render_frame(rotation_frame, glitch_state)
		section.val = lines
		section.opts.hl = utils.charhl_to_bytehl(character_ranges, lines)
	end

	apply_frame()

	return {
		section = section,
		width = WIDTH,
		tick_divisor = 1,
		wordmark_tick_divisor = 2,

		next_frame = function()
			rotation_frame = rotation_frame % ROTATION_FRAMES + 1
			apply_frame()
		end,

		next_wordmark_frame = function()
			if glitch_remaining > 0 then
				glitch_remaining = glitch_remaining - 1
				if glitch_remaining == 0 then
					glitch_state.tearing = false
					glitch_state.chromatic = false
					glitch_state.block_noise = false
					glitch_state.scanline = false
					glitch_state.burst = false
					glitch_state.interference = false
					glitch_cooldown = random_int(3)
				end
			elseif glitch_cooldown > 0 then
				glitch_cooldown = glitch_cooldown - 1
			elseif random_int(100) <= 72 then
				local kind = random_int(7)
				glitch_state.tearing = kind == 1 or kind == 5 or kind == 6 or kind == 7
				glitch_state.chromatic = kind == 2 or kind == 5 or kind == 6
				glitch_state.block_noise = kind == 3 or kind == 5 or kind == 7
				glitch_state.scanline = kind == 4 or kind == 5
				glitch_state.burst = kind == 6
				glitch_state.interference = kind == 7
				glitch_state.seed = random_int(2147483646)
				glitch_remaining = random_int(4)
			end

			apply_frame()
		end,
	}
end

return M
