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

-- The logo stays static. Only the C concept panel beneath it changes.
M.animation = {
	speed = 2400,
	start_line = 9,

	frames = {
		{
			"  POINTERS",
			"  int value = 42;",
			"  int *ptr = &value;",
			"             ^",
			"             address-of",
		},
		{
			"  DEREFERENCE",
			"  int copy = *ptr;",
			"              ^",
			"              dereference",
			"  copy is now 42",
		},
		{
			"  MEMORY MAP",
			"  value @ 0x0010 = 42",
			"  ptr   @ 0x0020 = 0x0010",
			"  *ptr  -> 0x0010 -> 42",
			"  one pointer, one address",
		},
		{
			"  COMPILATION",
			"  main.c -> main.i",
			"  main.i -> main.s",
			"  main.s -> main.o",
			"  main.o -> cvim",
		},
		{
			"  REPRESENTATIONS",
			"  decimal      42",
			"  hexadecimal  0x2A",
			"  binary       00101010",
			"  same value, three forms",
		},
	},
}

return M
