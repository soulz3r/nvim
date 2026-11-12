# Development workflow

## Project metadata

YAP stores project metadata outside the repository at `stdpath("state")/yap/projects.json`. It records the last executable, arguments, run time, and last-opened time per normalized project root. It can read the previous `stdpath("state")/soul/projects.json` location as a migration fallback.

Project run records and argument history are stored under `stdpath("data")/yap`. These are runtime state and should not be committed.

## C tools

YAP keeps the C/C++ helper functionality available with only one default mapping:

| Mapping / Command | Action |
|---|---|
| `<leader>ch` | Switch between matching source and header files |
| `<leader>ci` | Insert an include directive |
| `<leader>cp` | Show project root, compile metadata, and attached LSP clients |
| `:CSwitchHeader` | Switch between matching source and header files |
| `:CProjectInfo` | Show project root, compile metadata, and attached LSP clients |

clangd still owns semantic navigation, references, rename, and diagnostics. These helpers intentionally avoid duplicating those features.

## Project runner UI

The project picker is implemented through `telescope-project.nvim`; YAP adds project-specific actions to the picker. `<leader>pp` opens it. In Insert mode, `Ctrl-g` builds and runs, `Ctrl-y` builds, `Ctrl-e` selects an executable, and `Ctrl-a` opens the action menu. Normal-mode equivalents are `gR`, `gB`, `gE`, `gC`, `gX`, `gS`, and `gA`. Direct project actions are exposed through the `<leader>p` mappings when YAP's Telescope integration is enabled.

The runner uses YAP's own floating-window helpers and retains ANSI colors and compiler diagnostic extraction. It does not use Nui or NuiComponents. The Neovim plugin spec declares Telescope and `telescope-project.nvim` as dependencies; keep those entries and `lazy-lock.json` in sync if the picker integration changes.

## UI helpers

`lua/soul/core/helpers/ui/init.lua` provides shared floating-window geometry, text-buffer windows, and highlight links. New custom windows should use these helpers rather than reimplementing sizing and close mappings. YAP owns its runner presentation and its `Yap*` highlight namespace.

## Checks

Run `bash scripts/check.sh` for JSON validation, lockfile validation, regression guards for known configuration invariants, deprecated/private API scans, Lua syntax checks, and a headless core/plugin-spec smoke test. Use `stylua .` to apply the repository formatting rules from `.stylua.toml`; CI checks formatting for files touched by the core maintenance workflow. GitHub Actions runs these checks against the latest Neovim stable release and nightly build on Windows and Linux. The smoke test does not install or execute third-party plugin configurations, so it cannot replace interactive checks of plugin behavior.
