# Development workflow

## Project metadata

YAP stores project metadata outside the repository at `stdpath("state")/yap/projects.json`. It records the last executable, arguments, run time, and last-opened time per normalized project root. It can read the previous `stdpath("state")/soul/projects.json` location as a migration fallback.

Project run records and argument history are stored under `stdpath("data")/yap`. These are runtime state and should not be committed.

## C tools

YAP provides the C/C++ helpers:

| Mapping | Action |
|---|---|
| `<leader>ch` | Switch between matching source and header files |
| `<leader>ci` | Insert an include directive |
| `<leader>pi` | Show project root, compile metadata, and attached LSP clients |

Commands: `:CProjectInfo` and `:CSwitchHeader`.

clangd still owns semantic navigation, references, rename, and diagnostics. These helpers intentionally avoid duplicating those features.

## Project runner UI

The project switcher and runner are implemented in YAP and rendered with `nui-components.nvim` over `nui.nvim`. The switcher composes reusable input, panel, selectable-list, description, and keymap-hint components. It starts in Normal mode, supports filtering in Insert mode, and shows a README preview only when the selected C project has `README.md` or `readme.md`. Selecting a project changes the global working directory. The runner presents a live operation summary above a separate process-output pane. The output buffer remains read-only while retaining ANSI colors and compiler diagnostic extraction.

The plugin configuration in `lua/soul/plugins/yap.lua` declares both UI libraries directly. Keep the dependency list and `lazy-lock.json` in sync when changing the runner UI dependencies.

## UI helpers

`lua/soul/core/helpers/ui/init.lua` provides shared floating-window geometry, text-buffer windows, and highlight links. New custom windows should use these helpers rather than reimplementing sizing and close mappings. YAP owns its runner presentation and its `Yap*` highlight namespace.

## Checks

Run `bash scripts/check.sh` for JSON and repository hygiene checks. When Lua 5.1 is installed, the script also parses every Lua file. When Neovim is installed, it runs a headless startup smoke test with plugins disabled.
