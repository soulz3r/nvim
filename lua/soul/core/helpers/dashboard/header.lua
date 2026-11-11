local M = {}

M.lines = {
	"███████╗ ██████╗ ██╗   ██╗██╗灵魂",
	"██╔════╝██╔═══██╗██║   ██║██║士兵",
	"███████╗██║no ██║██║   ██║██║国王",
	"╚════██║██║me ██║██║   ██║██║没了",
	"███████║╚██████╔╝╚████╔╝███████╗",
	"╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝",
}

-- Character-based highlight ranges. Alpha converts these to byte positions.
M.highlights = {
	{
		{ "AlphaGreen", 0, 29 },
		{ "AlphaYellow", 29, 31 },
	},

	{
		{ "AlphaGreen", 0, 20 },
		{ "AlphaRed", 20, 22 },
		{ "AlphaGreen", 22, 29 },
		{ "AlphaYellow", 29, 31 },
	},

	{
		{ "AlphaGreen", 0, 11 },
		{ "AlphaYellow", 11, 13 },
		{ "AlphaGreen", 13, 20 },
		{ "AlphaRed", 20, 22 },
		{ "AlphaGreen", 22, 29 },
		{ "AlphaYellow", 29, 31 },
	},

	{
		{ "AlphaGreen", 0, 11 },
		{ "AlphaYellow", 11, 13 },
		{ "AlphaGreen", 13, 20 },
		{ "AlphaRed", 20, 22 },
		{ "AlphaGreen", 22, 29 },
		{ "AlphaYellow", 29, 31 },
	},

	{
		{ "AlphaGreen", 0, 34 },
	},

	{
		{ "AlphaGreen", 0, 34 },
	},
}

-- Animation data is kept separate from the Alpha section that consumes it.
M.animation = {
	speed = 150,

	fragments = {
		DA = { "d ", "da", "da", "d ", "  " },
		EM = { "e ", "em", "em", "e ", "  " },
		ON = { "o ", "on", "on", "o ", "  " },
	},

	lines = {
		[2] = {
			"██╔════╝██╔═══██╗██║",
			" ██║██║士兵",
		},

		[3] = {
			"███████╗██║no ██║██║",
			" ██║██║国王",
		},

		[4] = {
			"╚════██║██║me ██║██║",
			" ██║██║没了",
		},
	},

	steps = {
		-- DA
		{ 2, "DA", 1 },
		{ 2, "DA", 2 },
		{ 2, "DA", 3 },

		-- EM
		{ 3, "EM", 1 },
		{ 3, "EM", 2 },
		{ 3, "EM", 3 },

		-- ON
		{ 4, "ON", 1 },
		{ 4, "ON", 2 },
		{ 4, "ON", 3 },

		-- Erase ON
		{ 4, "ON", 4 },
		{ 4, "ON", 5 },

		-- Erase EM
		{ 3, "EM", 4 },
		{ 3, "EM", 5 },

		-- Erase DA
		{ 2, "DA", 4 },
		{ 2, "DA", 5 },
	},
}

return M
