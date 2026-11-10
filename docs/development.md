# Development workflow

## Project metadata

Project metadata is stored outside the repository at `stdpath("state")/soul/projects.json`. It records the last executable, arguments, run time, and last-opened time per normalized project root. It is safe to delete; the registry is rebuilt as projects are used.

## C tools

In C and C++ buffers:

| Mapping | Action |
|---|---|
| `<leader>ch` | Switch between matching source and header files |
| `<leader>ci` | Insert an include directive |
| `<leader>cp` | Show project root, compile metadata, and attached LSP clients |

Commands: `:CProjectInfo` and `:CSwitchHeader`.

clangd still owns semantic navigation, references, rename, and diagnostics. These helpers intentionally avoid duplicating those features.

## UI helpers

`lua/soul/ui/init.lua` provides shared floating-window geometry, text-buffer windows, and highlight links. New custom windows should use these helpers rather than reimplementing sizing and close mappings.

## Checks

Run `bash scripts/check.sh` for JSON and repository hygiene checks. When Lua 5.1 is installed, the script also parses every Lua file. When Neovim is installed, it runs a headless startup smoke test with plugins disabled.
