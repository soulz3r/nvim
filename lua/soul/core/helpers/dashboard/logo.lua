local M = {}
local FrameProfile = require("soul.core.performance.animation")

local WIDTH = 66
local HEIGHT = 15
local C_WIDTH = 25
local C_HEIGHT = 13
local CENTER_X = 11
local CENTER_Y = 7
local ROTATION_FRAMES = 96
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
	"CvimGlitchRed",
	"CvimGlitchOrange",
	"CvimGlitchYellow",
	"CvimGlitchLime",
	"CvimGlitchCyan",
	"CvimGlitchBlue",
	"CvimGlitchViolet",
	"CvimGlitchWhite",
}

local GLITCH_PALETTE = {
	CvimGlitchRed = "#ff304f",
	CvimGlitchOrange = "#ff8c24",
	CvimGlitchYellow = "#fff04a",
	CvimGlitchLime = "#9dff00",
	CvimGlitchCyan = "#00f5ff",
	CvimGlitchBlue = "#287bff",
	CvimGlitchViolet = "#8a4dff",
	CvimGlitchWhite = "#f4fbff",
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

-- The surface never changes. Build its trigonometric coordinates only
-- when the dashboard first requests a rotation frame, not when this module
-- is imported by another dashboard helper.
local SURFACE_SAMPLES

local function get_surface_samples()
	if SURFACE_SAMPLES then
		return SURFACE_SAMPLES
	end

	local started = FrameProfile.enabled and vim.uv.hrtime() or nil
	local samples = {}

	for theta_step = 0, 144 do
		local theta = math.rad(48 + theta_step * (264 / 144))
		local theta_cos = math.cos(theta)
		local theta_sin = math.sin(theta)

		for phi_step = 0, 63 do
			local phi = phi_step * (2 * math.pi / 64)
			local phi_cos = math.cos(phi)
			local phi_sin = math.sin(phi)
			local radius = 1 + 0.23 * phi_cos

			samples[#samples + 1] = {
				x = radius * theta_cos,
				y = radius * theta_sin,
				z = 0.23 * phi_sin,
				normal_x = phi_cos * theta_cos,
				normal_y = phi_cos * theta_sin,
				normal_z = phi_sin,
			}
		end
	end

	SURFACE_SAMPLES = samples

	if started then
		FrameProfile.record("logo.samples", (vim.uv.hrtime() - started) / 1e6)
	end

	return SURFACE_SAMPLES
end

local LIGHT_X, LIGHT_Y, LIGHT_Z = -0.35, 0.55, 0.76
local LIGHT_LENGTH = math.sqrt(LIGHT_X ^ 2 + LIGHT_Y ^ 2 + LIGHT_Z ^ 2)
LIGHT_X = LIGHT_X / LIGHT_LENGTH
LIGHT_Y = LIGHT_Y / LIGHT_LENGTH
LIGHT_Z = LIGHT_Z / LIGHT_LENGTH

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

-- Keep every intermediate below 2^53 so Lua's double-backed numbers retain
-- exact integer arithmetic. The frame changes the pattern during an event.
local function glitch_noise(row, column, seed, frame, salt)
	local value = seed % 2147483647
	value = (value * 48271 + row * 97 + column * 193 + salt * 389) % 2147483647
	value = (value * 48271 + frame * 997 + row * 31 + column * 17) % 2147483647
	return value
end

-- Build C rotation frames on demand and cache them for the dashboard
-- instance. Wordmark updates composite cached pixels without repeating the
-- surface projection, lighting, or depth tests.
local function build_c_frame(frame)
	local rotation = (frame - 1) * (2 * math.pi / ROTATION_FRAMES)
	local cosine = math.cos(rotation)
	local sine = math.sin(rotation)
	local depth = create_grid(C_WIDTH, C_HEIGHT, -math.huge)
	local pixels = create_grid(C_WIDTH, C_HEIGHT, " ")
	local groups = create_grid(C_WIDTH, C_HEIGHT, nil)

	-- Project one rotation from the immutable surface samples. Frames are
	-- cached on demand so startup only pays for the first visible rotation.
	for _, sample in ipairs(get_surface_samples()) do
		local projected_x = sample.x * cosine + sample.z * sine
		local projected_z = -sample.x * sine + sample.z * cosine
		local column = math.floor(CENTER_X + projected_x * 9 + 0.5)
		local row = math.floor(CENTER_Y - sample.y * 5 + 0.5)

		if column >= 1 and column <= C_WIDTH and row >= 1 and row <= C_HEIGHT and projected_z > depth[row][column] then
			depth[row][column] = projected_z

			local normal_x = sample.normal_x * cosine + sample.normal_z * sine
			local normal_z = -sample.normal_x * sine + sample.normal_z * cosine
			local diffuse = math.max(0, normal_x * LIGHT_X + sample.normal_y * LIGHT_Y + normal_z * LIGHT_Z)
			local view = math.max(0, normal_z)
			local specular = view ^ 10
			local shade = math.min(1, 0.14 + diffuse * 0.72 + specular * 0.42)
			local glyph_index = math.floor(shade * (#glyphs - 1)) + 1

			pixels[row][column] = glyphs[glyph_index]
			groups[row][column] = shade > 0.82 and "AlphaAqua" or shade > 0.48 and "AlphaTeal" or "AlphaGreen"
		end
	end

	return {
		pixels = pixels,
		groups = groups,
	}
end

local function render_frame(c_frame, glitch_state)
	local pixels = c_frame.pixels
	local groups = c_frame.groups

	-- Glitch events are selected by the animation state machine, not a fixed
	-- repeating frame cycle.
	local tearing = glitch_state.tearing
	local chromatic = glitch_state.chromatic
	local block_noise = glitch_state.block_noise
	local scanline = glitch_state.scanline
	local burst = glitch_state.burst
	local interference = glitch_state.interference
	local glitch_seed = glitch_state.seed
	local glitch_frame = glitch_state.frame or 0
	local lines = {}
	local ranges = {}

	for row = 1, HEIGHT do
		local cells = {}
		local cell_groups = {}
		local art_row = row - ART_TOP + 1
		local art_chars = WORDMARK_CHARS[art_row]

		-- Tear a randomly sized fragment at a random position. The rest of
		-- every line stays exactly where the ASCII artwork placed it.
		local tear_row = glitch_seed % (#WORDMARK_CHARS - 1) + 1
		local tear_chars = WORDMARK_CHARS[tear_row]
		local first_glyph = 1
		local last_glyph = #tear_chars
		while first_glyph <= last_glyph and tear_chars[first_glyph] == " " do
			first_glyph = first_glyph + 1
		end
		while last_glyph >= first_glyph and tear_chars[last_glyph] == " " do
			last_glyph = last_glyph - 1
		end
		local tear_span = math.max(1, last_glyph - first_glyph + 1)
		local tear_start = first_glyph + (math.floor(glitch_seed / 29) % tear_span)
		local tear_end = math.min(last_glyph, tear_start + 7 + (math.floor(glitch_seed / 43) % 14))
		local tear_shift = (math.floor(glitch_seed / 113 + glitch_frame * 3) % 13) - 6
		if tear_shift == 0 then
			tear_shift = 1
		end
		local burst_row = math.floor(glitch_seed / 7) % (#WORDMARK_CHARS - 1) + 1
		local burst_start = 1 + (math.floor(glitch_seed / 17) % 20)
		local burst_end = burst_start + 9 + (math.floor(glitch_seed / 43) % 16)
		local burst_shift = (math.floor(glitch_seed / 97 + glitch_frame * 5) % 19) - 9
		local interference_row = (math.floor(glitch_seed / 53 + glitch_frame * 3) % (#WORDMARK_CHARS - 1)) + 1
		local interference_shift = (math.floor(glitch_seed / 71 + glitch_frame * 2) % 7) - 3
		local row_shift = burst and art_row == burst_row and burst_shift or 0
		local tear_active = tearing and art_row == tear_row

		for column = 1, WIDTH do
			local char = " "
			local group

			if column <= C_WIDTH and row <= C_HEIGHT then
				char = pixels[row][column]
				group = groups[row][column]
			end

			local art_column = column - ART_START + 1
			if art_chars and art_column >= 1 and art_column <= #art_chars then
				local in_burst = burst
					and art_row == burst_row
					and art_column >= burst_start
					and art_column <= burst_end
				local in_tear = tear_active and art_column >= tear_start and art_column <= tear_end
				local in_interference = interference and art_row == interference_row
				local source_column = art_column
				if in_tear then
					source_column = art_column - tear_shift
				elseif in_burst then
					source_column = art_column - row_shift
				elseif in_interference then
					source_column = art_column - interference_shift
				end
				char = art_chars[source_column] or " "
				group = char ~= " " and wordmark_group(char) or nil
				local noise = glitch_noise(art_row, art_column, glitch_seed, glitch_frame, 2)

				if in_tear or in_burst then
					group = GLITCH_COLORS[noise % #GLITCH_COLORS + 1]
					-- Preserve the logo silhouette while animating sparse
					-- substitutions inside the displaced fragment.
					if noise % (in_burst and 7 or 13) == 0 then
						char = GLITCH_BLOCKS[math.floor(noise / 17) % #GLITCH_BLOCKS + 1]
					end
				elseif in_interference and char ~= " " then
					group = GLITCH_COLORS[(noise % 4) + 1]
					if noise % 11 == 0 then
						char = GLITCH_BLOCKS[math.floor(noise / 17) % #GLITCH_BLOCKS + 1]
					end
				end

				-- Noise stays local to the active fragment or interference row.
				if block_noise and (in_tear or in_burst or in_interference) and noise % 17 == 0 then
					char = GLITCH_BLOCKS[math.floor(noise / 17) % #GLITCH_BLOCKS + 1]
					group = GLITCH_COLORS[math.floor(noise / 71) % #GLITCH_COLORS + 1]
				end
			end

			cells[column] = char
			cell_groups[column] = group
		end

		-- Add a sparse one-cell color ghost beside the original glyph.
		-- The original character remains intact, keeping the wordmark readable.
		if chromatic and art_chars and art_row == tear_row then
			for art_column = tear_start, tear_end do
				local source = art_chars[art_column]
				local noise = glitch_noise(art_row, art_column, glitch_seed, glitch_frame, 3)
				if source and source ~= " " and noise % 5 == 0 then
					local ghost_offset = (math.floor(noise / 13) % 5) - 2
					if ghost_offset == 0 then
						ghost_offset = glitch_frame % 2 == 0 and 1 or -1
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
		if scanline and art_chars and #art_chars > 0 and art_row == tear_row then
			for column = ART_START + tear_start - 1, math.min(WIDTH, ART_START + tear_end - 1) do
				local noise = glitch_noise(art_row, column - ART_START + 1, glitch_seed, glitch_frame, 5)
				if noise % 11 == 0 then
					cells[column] = GLITCH_BLOCKS[math.floor(noise / 17) % #GLITCH_BLOCKS + 1]
					cell_groups[column] = GLITCH_COLORS[noise % #GLITCH_COLORS + 1]
				end
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
	FrameProfile.setup()
	setup_glitch_highlights()
	local section = {
		type = "text",
		val = {},
		opts = {
			position = "center",
			hl = {},
		},
	}

	-- Cache the finite rotation set on demand. The first frame is ready for
	-- Alpha's initial render; later frames are projected during animation ticks.
	local c_frames = {}
	local rotation_frame = 1

	local function get_c_frame(frame)
		local cached = c_frames[frame]
		if cached then
			return cached
		end

		local started = FrameProfile.enabled and vim.uv.hrtime() or nil
		cached = build_c_frame(frame)
		c_frames[frame] = cached

		if started then
			FrameProfile.record("logo.project", (vim.uv.hrtime() - started) / 1e6)
		end

		return cached
	end

	get_c_frame(rotation_frame)
	local random_state = math.floor((vim.uv and vim.uv.hrtime and vim.uv.hrtime() or os.time()) % 2147483646) + 1
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
		frame = 0,
	}
	local glitch_remaining = 0
	local glitch_cooldown = 0

	local function apply_frame(profile_frame)
		local started = profile_frame and FrameProfile.enabled and vim.uv.hrtime() or nil
		local lines, character_ranges = render_frame(get_c_frame(rotation_frame), glitch_state)
		if started then
			FrameProfile.record("logo.render", (vim.uv.hrtime() - started) / 1e6)
		end

		section.val = lines
		started = profile_frame and FrameProfile.enabled and vim.uv.hrtime() or nil
		section.opts.hl = utils.charhl_to_bytehl(character_ranges, lines)
		if started then
			FrameProfile.record("logo.highlights", (vim.uv.hrtime() - started) / 1e6)
		end
	end

	apply_frame(false)

	return {
		section = section,
		width = WIDTH,
		tick_divisor = 1,
		wordmark_tick_divisor = 2,

		next_frame = function()
			rotation_frame = rotation_frame % ROTATION_FRAMES + 1
			apply_frame(true)
		end,

		next_wordmark_frame = function()
			glitch_state.frame = glitch_state.frame + 1

			if glitch_remaining > 0 then
				glitch_remaining = glitch_remaining - 1
				if glitch_remaining == 0 then
					glitch_state.tearing = false
					glitch_state.chromatic = false
					glitch_state.block_noise = false
					glitch_state.scanline = false
					glitch_state.burst = false
					glitch_state.interference = false
					-- Leave a noticeable quiet interval after every event.
					-- These are wordmark updates, not raw timer milliseconds.
					glitch_cooldown = random_int(11) + 7
				end
			elseif glitch_cooldown > 0 then
				glitch_cooldown = glitch_cooldown - 1
			elseif random_int(100) <= 65 then
				local kind = random_int(7)
				glitch_state.tearing = kind == 1 or kind == 5 or kind == 6 or kind == 7
				glitch_state.chromatic = kind == 2 or kind == 5 or kind == 6
				glitch_state.block_noise = kind == 3 or kind == 5 or kind == 7
				glitch_state.scanline = kind == 4 or kind == 5
				glitch_state.burst = kind == 6
				glitch_state.interference = kind == 7
				glitch_state.seed = random_int(2147483646)
				glitch_state.frame = 0
				-- A mix of quick flickers, medium disruptions, and occasional
				-- longer holds. Duration is measured in wordmark updates.
				local duration_roll = random_int(10)
				if duration_roll <= 4 then
					glitch_remaining = 1
				elseif duration_roll <= 7 then
					glitch_remaining = random_int(3) + 2
				else
					glitch_remaining = random_int(5) + 6
				end
			else
				-- A missed trigger also waits before trying again, rather than
				-- rolling for a new event on every single animation update.
				glitch_cooldown = random_int(4) + 2
			end

			apply_frame(true)
		end,
	}
end

return M
