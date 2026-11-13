local M = {}

local WIDTH = 31
local HEIGHT = 13
local C_WIDTH = 25
local C_HEIGHT = 13
local CENTER_X = 13
local CENTER_Y = 7
local ROTATION_FRAMES = 36

local glyphs = { ".", ":", "-", "=", "+", "*", "#", "%", "@" }

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

local function render_frame(frame)
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

			if column >= 1 and column <= C_WIDTH and row >= 1 and row <= C_HEIGHT
				and projected_z > depth[row][column]
			then
				depth[row][column] = projected_z

				local normal_x = phi_cos * theta_cos
				local normal_y = phi_cos * theta_sin
				local normal_z = phi_sin
				local rotated_normal_x = normal_x * cosine + normal_z * sine
				local rotated_normal_z = -normal_x * sine + normal_z * cosine

				local diffuse = math.max(
					0,
					rotated_normal_x * light_x
						+ normal_y * light_y
						+ rotated_normal_z * light_z
				)
				local shade = 0.2 + diffuse * 0.8
				local glyph_index = math.floor(shade * (#glyphs - 1)) + 1

				pixels[row][column] = glyphs[glyph_index]
				groups[row][column] = shade > 0.72 and "AlphaAqua"
					or shade > 0.46 and "AlphaTeal"
					or "AlphaGreen"
			end
		end
	end

	local lines = {}
	local ranges = {}

	for row = 1, HEIGHT do
		local line = {}
		local line_ranges = {}
		local active_group
		local range_start

		for column = 1, WIDTH do
			local char = " "
			local group

			if column <= C_WIDTH then
				char = pixels[row][column]
				group = groups[row][column]
			end

			-- Keep the wordmark independent of the rotating C.
			if row == 7 and column >= 28 and column <= 30 then
				local wordmark = { "v", "i", "m" }
				char = wordmark[column - 27]
				group = "AlphaYellow"
			end

			line[column] = char

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

		if active_group then
			line_ranges[#line_ranges + 1] = {
				active_group,
				range_start - 1,
				WIDTH,
			}
		end

		lines[row] = table.concat(line)
		ranges[row] = line_ranges
	end

	return lines, ranges
end

function M.build()
	local utils = require("alpha.utils")
	local section = {
		type = "text",
		val = {},
		opts = {
			position = "center",
			hl = {},
		},
	}

	local frame = 1

	local function apply_frame()
		local lines, character_ranges = render_frame(frame)
		section.val = lines
		section.opts.hl = utils.charhl_to_bytehl(character_ranges, lines)
	end

	apply_frame()

	return {
		section = section,
		width = WIDTH,
		tick_divisor = 2,

		next_frame = function()
			frame = frame % ROTATION_FRAMES + 1
			apply_frame()
		end,
	}
end

return M
