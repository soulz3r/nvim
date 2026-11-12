# Development workflow

## Project metadata

YAP stores project metadata outside the repository at `stdpath("state")/yap/projects.json`. It records the last executable, arguments, run time, and last-opened time per normalized project root. It can read the previous `stdpath("state")/soul/projects.json` location as a migration fallback.

Project run records and argument history are stored under `stdpath("data")/yap`. These are runtime state and should not be committed.

## C tools

YAP registers three buffer-local C/C++ helper mappings:

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

## Lua formatting

Lua source uses hard tabs with a display width of four, as defined in `.stylua.toml`. Keep indentation consistent and run `stylua .` before committing formatting changes. The repository check enforces tabs across every Lua source file. It exempts only the literal body of the multiline Ex menu command in `lua/soul/core/keymaps.lua`; indentation before and after that command remains checked. Unit tests cover the exception boundary, mixed indentation, and unterminated command blocks.

## Checks

Run `bash scripts/check.sh` for JSON and lockfile validation, Python checker unit tests, Lua indentation and line-ending checks, regression guards, deprecated/private API scans, Lua syntax checks, full-repository StyLua validation (when StyLua is installed), and headless Neovim smoke/integration tests. Python 3 is required for this script. Set `REQUIRE_LUA=1`, `REQUIRE_NVIM=1`, and `REQUIRE_STYLUA=1` in environments where all three tools must be present. Use `stylua .` to apply the formatting rules from `.stylua.toml`.

The headless integration test exercises the custom DAP plugin configuration with stubbed external plugin APIs, verifies launch argument persistence and cancellation, and tests the shared floating-output window lifecycle. A separate Mini Notify test exercises concurrent progress from multiple clients, delayed cleanup invalidation, and client detach behavior. The core smoke test also verifies child-process timeout cleanup and confirms that a completed process exit code of 124 is not mistaken for a timeout. These tests verify integration contracts without downloading plugins. They do not prove that LLDB, language servers, Telescope, Mini Files, ToggleTerm, or Neovide work on a particular machine.

GitHub Actions checks Neovim stable and nightly on Windows and Linux, plus stable Neovim on macOS. Windows CI prints the PowerShell resolver duration when profiling is enabled. The resolver checks an inherited `PSHOME` executable before running slower WindowsApps and AppX discovery probes.

## DAP module boundaries

The DAP entry point currently owns adapter setup, project selection, registry synchronization, launch lifecycle, UI lifecycle, and REPL mappings. These pieces share session and selected-project state, so splitting them solely to reduce file length would add module boundaries without removing meaningful coupling. The argument parser is already extracted as a small independently tested helper. Extract project discovery or REPL behavior only when it gains a stable interface and direct tests.

## Manual platform checks

Headless CI cannot exercise a user's terminal emulator, external toolchain, clipboard, or GUI. Run the relevant checks on each platform you actually use:

| Platform | Manual checks |
|---|---|
| Windows | PowerShell 7 resolution and ToggleTerm; clangd; LLDB DAP; C build/run; clipboard |
| WSL | Linux shell and compiler; Windows clipboard bridge; projects under the mounted Windows filesystem; LLDB DAP |
| Linux | Native shell and clipboard; clangd; LLDB DAP; C build/run; Mini Files and terminal behavior |
| macOS | POSIX shell; available compiler/debugger; clipboard; C build/run |
| Termux | Platform detection; available shell/compiler; project paths and terminal behavior |
| Neovide | GUI startup, font, transparency, borders, cursor/scroll behavior, and window lifecycle |

Do not treat a platform as tested merely because its configuration module imports successfully. Record unavailable external tools as untested rather than silently counting them as passes.
