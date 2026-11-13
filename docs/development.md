# Development workflow

## Project metadata

YAP stores its own project metadata outside the repository at `stdpath("state")/yap/projects.json`, including its last executable, run arguments, run time, and last-opened time per normalized project root. It can read the previous `stdpath("state")/soul/projects.json` location as a migration fallback. DAP-specific executable and launch-argument settings are no longer written to this registry.

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

The headless integration test exercises the custom DAP plugin configuration with stubbed external plugin APIs, verifies launch argument persistence and cancellation, and tests the shared floating-output window lifecycle. DAP project persistence is tested against its own JSON registry, independently of YAP. Separate Mini Notify tests exercise concurrent progress from multiple clients, delayed cleanup invalidation, and client detach behavior. DAP registry migration tests verify successful imports, backup collision handling, malformed JSON preservation, failed-write preservation, and missing-file handling. DAP executable discovery tests cover root and common build directories, output ranking, ignored dependency directories, and traversal depth limits. DAP path/project tests cover canonical normalization, path-boundary checks, nearest DAP-registered ancestor resolution, independent registry persistence, and fallback to the current file's directory. The core smoke test also verifies child-process timeout cleanup and confirms that a completed process exit code of 124 is not mistaken for a timeout. These tests verify integration contracts without downloading plugins. They do not prove that LLDB, language servers, Telescope, Mini Files, ToggleTerm, or Neovide work on a particular machine.

GitHub Actions runs full-repository StyLua validation and static checks on Ubuntu. A separate compatibility matrix runs the headless repository/integration checks against Neovim stable and nightly on Windows and Linux, plus stable Neovim on macOS. Windows CI prints the PowerShell resolver duration when profiling is enabled. Its smoke test checks invalid inherited `PWSH` and `PSHOME` hints, rejection of Windows PowerShell 5.1 when PowerShell 7 is available, and a PowerShell 7 executable path with spaces. The resolver checks an inherited `PSHOME` executable before running slower WindowsApps and AppX discovery probes.

## Performance and resource lifecycle

The resource lifecycle implementation lives under `lua/soul/core/lifecycle/`. Use cleanup scopes for timers and autocmd groups, and give every long-lived resource an explicit owner and teardown path. Alpha is a startup-only surface; its animation timer and dashboard state are released when the Alpha buffer is left. LSP clients are shut down gracefully only after their final loaded attached buffer is detached and the idle timeout expires. Hidden buffers intentionally keep their server alive.

Run `nvim --headless --clean -u NONE -l scripts/check-lifecycle.lua` to test cleanup-scope behavior and idle LSP shutdown/cancellation with fake clients. The repository check runs this test automatically. See [performance.md](performance.md) for manual lifecycle checks and repeatable startup/idle benchmarks.

## DAP module boundaries

The DAP plugin specification in `lua/soul/lsp/dap.lua` is the composition layer. Keep it limited to loading the dependencies and wiring their setup functions. Focused helpers own independent concerns:

- `lua/soul/core/helpers/dap/path.lua`: shared path normalization, case-aware project keys, containment checks, and executable checks.
- `lua/soul/core/helpers/dap/project.lua`: public composition layer for the focused DAP project modules.
- `lua/soul/core/helpers/dap/project/store.lua`: DAP project metadata reads/writes and registered-project lookup.
- `lua/soul/core/helpers/dap/project/registry.lua`: independent JSON persistence.
- `lua/soul/core/helpers/dap/project/resolver.lua`: buffer-aware root detection and manual project activation.
- `lua/soul/core/helpers/dap/project/selection.lua`: saved-project picker and executable selection UI.
- `lua/soul/core/helpers/dap/launch.lua`: LLDB adapter/configuration, executable choice, and launch argument prompting/persistence.
- `lua/soul/core/helpers/dap/keymaps.lua`: grouped session/project, breakpoint, stepping, evaluation/REPL, and UI mappings.
- `lua/soul/core/helpers/dap/args.lua`: portable launch-argument parsing and formatting.
- `lua/soul/core/helpers/dap/executables.lua`: bounded project executable discovery and ranking.
- `lua/soul/core/helpers/dap/registry.lua`: safe migration of legacy DAP files and one-time import of old DAP-specific fields from YAP's former registry.
- `lua/soul/core/helpers/dap/repl.lua`: REPL discovery, focus, and Telescope-backed search.
- `lua/soul/core/helpers/dap/ui.lua`: DAP UI setup and restoration of the original source window after a session.

Keep only the coordination between these modules in the plugin entry point. Do not make helpers depend on one another's hidden locals or pass around a shared mutable state bag.

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

Do not treat a platform as tested merely because its configuration module imports successfully. Record unavailable external tools as untested rather than silently counting them as passes. The real-plugin and external-tool procedure is in [manual-testing.md](manual-testing.md); [plugin-inventory.md](plugin-inventory.md) records plugin purpose, and [contributing.md](contributing.md) describes the maintenance workflow.
