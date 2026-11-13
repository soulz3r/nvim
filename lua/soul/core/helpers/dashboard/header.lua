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
	"  FIRST PROGRAM",
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
				"  FIRST PROGRAM",
				"  int main(void) {",
				"    return 0;",
				"  }",
				"  main is the entry point",
			},
		},
		{
			lines = {
				"  COMPILATION",
				"  main.c -> main.i",
				"  main.i -> main.s",
				"  main.s -> main.o",
				"  then the linker builds cvim",
			},
		},
		{
			lines = {
				"  OUTPUT",
				"  #include <stdio.h>",
				"  puts(\"Hello, C\");",
				"  return 0;",
				"  puts writes to stdout",
			},
		},
		{
			lines = {
				"  TYPES",
				"  int count = 42;",
				"  double ratio = 0.75;",
				"  char grade = 'A';",
				"  types define stored data",
			},
		},
		{
			lines = {
				"  CONSTANTS",
				"  const int limit = 64;",
				"  enum { MAX = 32 };",
				"  static const int id = 7;",
				"  const prevents modification",
			},
		},
		{
			lines = {
				"  OPERATORS",
				"  int sum = count + 8;",
				"  int odd = sum % 2;",
				"  sum += 1;",
				"  operators form expressions",
			},
		},
		{
			lines = {
				"  CONTROL FLOW",
				"  if (count > 0) {",
				"    count--;",
				"  } else {",
				"    count = 0;",
				"  branches control execution",
			},
		},
		{
			lines = {
				"  FUNCTIONS",
				"  int add(int a, int b) {",
				"    return a + b;",
				"  }",
				"  functions reuse behavior",
			},
		},
		{
			lines = {
				"  ARRAYS",
				"  int values[3] = {2, 4, 6};",
				"  values[0] = 10;",
				"  size_t n = 3;",
				"  arrays store adjacent items",
			},
		},
		{
			lines = {
				"  STRINGS",
				"  char name[] = \"C lang\";",
				"  const char *s = name;",
				"  size_t n = strlen(s);",
				"  strings end with '\\0'",
			},
		},
		{
			lines = {
				"  STRUCTURES",
				"  struct Point { int x, y; };",
				"  struct Point p = {2, 4};",
				"  p.x = 8;",
				"  structs group related data",
			},
		},
		{
			lines = {
				"  POINTERS",
				"  int value = 42;",
				"  int *ptr = &value;",
				"  ptr holds an address",
				"  pointers refer to objects",
			},
		},
		{
			lines = {
				"  DEREFERENCE",
				"  int copy = *ptr;",
				"  *ptr = 99;",
				"  read or write through ptr",
				"  star accesses the pointed value",
			},
		},
		{
			lines = {
				"  MEMORY",
				"  value @ 0x10 = 42",
				"  ptr   @ 0x20 = 0x10",
				"  *ptr -> 0x10 -> 42",
				"  an address identifies an object",
			},
		},
		{
			lines = {
				"  PREPROCESSOR",
				"  #include <stdint.h>",
				"  #if defined(DEBUG)",
				"  #define SIZE 256",
				"  #endif runs before compilation",
			},
		},
		{
			lines = {
				"  MACROS",
				"  #define SQR(x) ((x) * (x))",
				"  int area = SQR(side);",
				"  #undef SQR",
				"  macros expand before compiling",
			},
		},
		{
			lines = {
				"  DYNAMIC MEMORY",
				"  int *p = malloc(n * sizeof *p);",
				"  if (p) free(p);",
				"  check allocation before use",
				"  every allocation needs an owner",
			},
		},
		{
			lines = {
				"  FILE I O",
				"  FILE *f = fopen(path, \"rb\");",
				"  if (f) fclose(f);",
				"  check errors and close files",
				"  file handles own resources",
			},
		},
		{
			lines = {
				"  BITWISE",
				"  unsigned flags = 0;",
				"  flags |= 1u << 2;",
				"  int on = (flags & 4u) != 0;",
				"  masks operate on individual bits",
			},
		},
	},
}

return M
