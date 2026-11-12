local M = {}

M.lines = {
	" ██████╗██╗   ██╗██╗███╗   ███╗",
	"██╔════╝██║   ██║██║████╗ ████║",
	"██║     ██║   ██║██║██╔████╔██║",
	"██║     ╚██████╔╝██║██║╚██╔╝██║",
	"╚██████╗ ╚═════╝ ╚═╝██║ ╚═╝ ██║",
	" ╚═════╝",
	"   C, with a better editor.",
	"",
	"  POINTERS",
	"  int value = 42;",
	"  int *ptr = &value;",
	"             ^",
	"             address-of",
}

-- Character-based highlight ranges. Alpha converts these to byte positions.
M.highlights = {
	{
		{ "AlphaGreen", 0, 31 },
	},
	{
		{ "AlphaGreen", 0, 31 },
	},
	{
		{ "AlphaGreen", 0, 31 },
	},
	{
		{ "AlphaGreen", 0, 31 },
	},
	{
		{ "AlphaGreen", 0, 31 },
	},
	{
		{ "AlphaGreen", 0, 8 },
	},
	{
		{ "AlphaYellow", 0, 27 },
	},
}

-- The logo stays static. The panel below it is animated independently.
M.animation = {
	speed = 160,
	start_line = 9,
	chars_per_tick = 4,
	hold_ticks = 6,

	scenes = {
		{
			lines = {
				"  POINTERS",
				"  int value = 42;",
				"  int *ptr = &value;",
				"",
				"  &value gives the address",
			},
			cursor_line = 4,
			cursor_target = 14,
		},
		{
			lines = {
				"  DEREFERENCE",
				"  int *ptr = &value;",
				"  int copy = *ptr;",
				"",
				"  *ptr reads the stored value",
			},
			cursor_line = 4,
			cursor_target = 14,
		},
		{
			lines = {
				"  MEMORY MAP",
				"  value @ 0x0010 = 42",
				"  ptr   @ 0x0020 = 0x0010",
				"  *ptr  -> 0x0010 -> 42",
				"  pointer stores an address",
			},
		},
		{
			lines = {
				"  COMPILATION",
				"  main.c",
				"  main.i",
				"  main.s",
				"  main.o -> cvim",
			},
		},
		{
			lines = {
				"  REPRESENTATIONS",
				"  decimal      42",
				"  hexadecimal  0x2A",
				"  binary       00101010",
				"  same value, three forms",
			},
		},
	},
}

return M
