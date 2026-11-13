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
	"  01 / FIRST PROGRAM",
	"  int main(void) {",
	"      return 0;",
	"  }",
	"  execution starts in main",
}

M.highlights = {
	{ { "AlphaGreen", 0, 31 } },
	{ { "AlphaGreen", 0, 31 } },
	{ { "AlphaGreen", 0, 31 } },
	{ { "AlphaGreen", 0, 31 } },
	{ { "AlphaGreen", 0, 31 } },
	{ { "AlphaGreen", 0, 8 } },
	{ { "AlphaYellow", 0, 27 } },
}

-- The panel is a small C tutorial, ordered from fundamentals to advanced topics.
-- Each scene keeps the same five-line shape so the dashboard layout never jumps.
M.animation = {
	speed = 160,
	start_line = 9,
	chars_per_tick = 4,
	hold_ticks = 6,

	scenes = {
		{
			lines = {
				"  01 / FIRST PROGRAM",
				"  int main(void) {",
				"      return 0;",
				"  }",
				"  execution starts in main",
			},
		},
		{
			lines = {
				"  02 / OUTPUT",
				"  #include <stdio.h>",
				"  puts(\"Hello, C\");",
				"  return 0;",
				"  puts writes a line to stdout",
			},
		},
		{
			lines = {
				"  03 / TYPES",
				"  int count = 42;",
				"  double ratio = 0.75;",
				"  char grade = 'A';",
				"  types define size and meaning",
			},
		},
		{
			lines = {
				"  04 / CONSTANTS",
				"  const int limit = 64;",
				"  enum { MAX_ITEMS = 32 };",
				"  static const char *name = \"cvim\";",
				"  make values immutable when possible",
			},
		},
		{
			lines = {
				"  05 / OPERATORS",
				"  int total = count + 8;",
				"  int even = total % 2 == 0;",
				"  total += 1;",
				"  operators build expressions",
			},
		},
		{
			lines = {
				"  06 / CONTROL FLOW",
				"  if (count > 0) {",
				"      count--;",
				"  } else { count = 0; }",
				"  branches and loops direct execution",
			},
		},
		{
			lines = {
				"  07 / FUNCTIONS",
				"  int add(int a, int b) {",
				"      return a + b;",
				"  }",
				"  functions package reusable behavior",
			},
		},
		{
			lines = {
				"  08 / ARRAYS",
				"  int values[3] = { 2, 4, 6 };",
				"  values[0] = 10;",
				"  size_t length = 3;",
				"  arrays store adjacent elements",
			},
		},
		{
			lines = {
				"  09 / STRINGS",
				"  char name[] = \"C language\";",
				"  const char *text = name;",
				"  size_t length = strlen(text);",
				"  C strings end with a null byte",
			},
		},
		{
			lines = {
				"  10 / STRUCTURES",
				"  struct Point { int x, y; };",
				"  struct Point p = { .x = 2, .y = 4 };",
				"  p.x = 8;",
				"  structs group related data",
			},
		},
		{
			lines = {
				"  11 / POINTERS",
				"  int value = 42;",
				"  int *ptr = &value;",
				"  ptr stores value's address",
				"  pointers refer to other objects",
			},
		},
		{
			lines = {
				"  12 / DEREFERENCE",
				"  int *ptr = &value;",
				"  int copy = *ptr;",
				"  *ptr = 99;",
				"  dereference to read or modify",
			},
		},
		{
			lines = {
				"  13 / MEMORY",
				"  value @ 0x0010 = 42",
				"  ptr   @ 0x0020 = 0x0010",
				"  *ptr  -> 0x0010 -> 42",
				"  a pointer stores an address",
			},
		},
		{
			lines = {
				"  14 / PREPROCESSOR",
				"  #include <stdint.h>",
				"  #define BUFFER_SIZE 256",
				"  #if defined(DEBUG)",
				"  directives run before compilation",
			},
		},
		{
			lines = {
				"  15 / MACROS",
				"  #define SQUARE(x) ((x) * (x))",
				"  int area = SQUARE(side);",
				"  #undef SQUARE",
				"  parenthesize macro arguments carefully",
			},
		},
		{
			lines = {
				"  16 / DYNAMIC MEMORY",
				"  int *items = malloc(count * sizeof *items);",
				"  if (items != NULL) {",
				"      free(items);",
				"  }",
				"  every allocation needs a clear owner",
			},
		},
		{
			lines = {
				"  17 / FILE I O",
				"  FILE *file = fopen(path, \"rb\");",
				"  if (file != NULL) {",
				"      fclose(file);",
				"  }",
				"  check errors and close opened files",
			},
		},
		{
			lines = {
				"  18 / COMPILATION",
				"  main.c -> main.i",
				"  main.i -> main.s",
				"  main.s -> main.o -> cvim",
				"  preprocess, compile, assemble, link",
			},
		},
		{
			lines = {
				"  19 / BITWISE",
				"  unsigned flags = 0;",
				"  flags |= 1u << 2;",
				"  int enabled = (flags & 4u) != 0;",
				"  bits make compact flags and masks",
			},
		},
	},
}

return M
