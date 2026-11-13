local M = {}

local LINES = {
	"\\   /   _   |\\/|",
	" \\ /   | |  |  |",
	"  v    |_|  |  |",
	"            |  |",
	"            |\\/|",
}

local WIDTH = 16

function M.build()
	local utils = require("alpha.utils")
	local ranges = {}

	for line = 1, #LINES do
		ranges[line] = {
			{ "AlphaTeal", 0, 5 },
			{ "AlphaYellow", 8, 11 },
			{ "AlphaAqua", 12, WIDTH },
		}
	end

	local section = {
		type = "text",
		val = vim.deepcopy(LINES),
		opts = {
			position = "center",
			hl = utils.charhl_to_bytehl(ranges, LINES),
		},
	}

	return {
		section = section,
		width = WIDTH,
	}
end

return M
