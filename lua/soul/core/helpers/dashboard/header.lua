local M = {}

M.lines = {
	" ██████╗██╗   ██╗██╗███╗   ███╗",
	"██╔════╝██║   ██║██║████╗ ████║",
	"██║     ██║   ██║██║██╔████╔██║",
	"██║     ╚██████╔╝██║██║╚██╔╝██║",
	"╚██████╗ ╚═════╝ ╚═╝██║ ╚═╝ ██║",
	" ╚═════╝",
	"    C, with a better editor.",
	"",
	"   FIRST PROGRAM",
	"   int main(void) {",
	"     return 0;",
	"     ^",
	"   ---------------",
	"   return exits main",
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

-- The logo stays static. The C tutorial types one character at a time.
-- The caret points at the concept being explained in each scene.
M.animation = {
	speed = 65,
	start_line = 9,
	hold_ticks = 8,

	scenes = {
		{
			cursor_line = 4,
			cursor_token = "return",
			lines = {
				"  FIRST PROGRAM",
				"  int main(void) {",
				"    return 0;",
				"",
				"  ---------------",
				"  return exits main",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "->",
			lines = {
				"  COMPILATION",
				"  main.c -> main.i",
				"  main.i -> main.s",
				"",
				"  ---------------",
				"  compiler translates stages",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "puts",
			lines = {
				"  OUTPUT",
				"  #include <stdio.h>",
				'  puts("Hello, C");',
				"",
				"  ---------------",
				"  puts writes to stdout",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "double",
			lines = {
				"  TYPES",
				"  int count = 42;",
				"  double ratio = 0.75;",
				"",
				"  ---------------",
				"  double stores decimals",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "MAX",
			lines = {
				"  CONSTANTS",
				"  const int limit = 64;",
				"  enum { MAX = 32 };",
				"",
				"  ---------------",
				"  enum names integer constants",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "+=",
			lines = {
				"  OPERATORS",
				"  int sum = count + 8;",
				"  sum += 1;",
				"",
				"  ---------------",
				"  += updates the existing value",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "--",
			lines = {
				"  CONTROL FLOW",
				"  if (count > 0) {",
				"    count--;",
				"",
				"  ---------------",
				"  if runs only when true",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "a +",
			lines = {
				"  FUNCTIONS",
				"  int add(int a, int b) {",
				"    return a + b;",
				"",
				"  ---------------",
				"  return sends a value back",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "0",
			lines = {
				"  ARRAYS",
				"  int values[3] = {2, 4, 6};",
				"  values[0] = 10;",
				"",
				"  ---------------",
				"  index zero selects first item",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "'c'",
			lines = {
				"  STRINGS",
				'  char name[] = "C lang";',
				"  name[0] = 'c';",
				"",
				"  ---------------",
				"  strings are character arrays",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "Point",
			lines = {
				"  STRUCTURES",
				"  struct Point { int x, y; };",
				"  struct Point p = {2, 4};",
				"",
				"  ---------------",
				"  structs group related fields",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "&value",
			lines = {
				"  POINTERS",
				"  int value = 42;",
				"  int *ptr = &value;",
				"",
				"  ---------------",
				"  &value gives an address",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "*ptr",
			lines = {
				"  DEREFERENCE",
				"  int *ptr = &value;",
				"  int copy = *ptr;",
				"",
				"  ---------------",
				"  *ptr reads the pointed value",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "0x10",
			lines = {
				"  MEMORY",
				"  value @ 0x10 = 42",
				"  ptr @ 0x20 = 0x10",
				"",
				"  ---------------",
				"  ptr stores an address",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "#if",
			lines = {
				"  PREPROCESSOR",
				"  #include <stdint.h>",
				"  #if defined(DEBUG)",
				"",
				"  ---------------",
				"  directives run before compile",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "SQR",
			lines = {
				"  MACROS",
				"  #define SQR(x) ((x) * (x))",
				"  int area = SQR(side);",
				"",
				"  ---------------",
				"  macros expand before build",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "free",
			lines = {
				"  DYNAMIC MEMORY",
				"  p = malloc(n * sizeof *p);",
				"  if (p) free(p);",
				"",
				"  ---------------",
				"  free releases memory",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "fclose",
			lines = {
				"  FILE I O",
				'  FILE *f = fopen(path, "r");',
				"  if (f) fclose(f);",
				"",
				"  ---------------",
				"  close every opened file",
			},
		},
		{
			cursor_line = 4,
			cursor_token = "<<",
			lines = {
				"  BITWISE",
				"  unsigned flags = 0;",
				"  flags |= 1u << 2;",
				"",
				"  ---------------",
				"  masks select individual bits",
			},
		},
	},
}

return M
