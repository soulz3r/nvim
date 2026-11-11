# Configuration architecture

The entry point is `init.lua`. It loads core settings, registers plugin imports through `GET()`, and then starts Lazy.nvim.

## Core

| Path | Responsibility |
|---|---|
| `lua/soul/launch.lua` | Collect Lazy.nvim imports |
| `lua/soul/lazy.lua` | Bootstrap and configure Lazy.nvim |
| `lua/soul/core/options.lua` | Editor options, shell, clipboard, and UI defaults |
| `lua/soul/core/neovide.lua` | Neovide-only settings |
| `lua/soul/core/keymaps.lua` | Global keymaps and helper options |
| `lua/soul/core/autocmds.lua` | Core autocmds |
| `lua/soul/core/platform.lua` | Centralized operating-system and WSL detection |
| `lua/soul/core/helpers/paths.lua` | Project directory and external tool paths |
| `lua/soul/core/helpers/ui/init.lua` | UI initialization, shared floating-window geometry, and text windows |
| `lua/soul/core/helpers/ui/colors.lua` | Everforest palette and centralized editor/plugin highlight definitions |
| `lua/soul/core/helpers/ui/highlights.lua` | Shared semantic highlight links |
| `lua/soul/core/helpers/ui/floats.lua` | Shared border style, Telescope border glyphs, and float window highlights |

## Plugins

Plugin specifications live under `lua/soul/plugins` and `lua/soul/extras`.

- `lua/soul/plugins/telescope.lua` owns general Telescope setup and pickers.
- `lua/soul/plugins/yap.lua` configures YAP, its project directory, plugin-owned highlight groups, and direct dependencies.
- `soulz3r/yap.nvim` owns C project detection, build/clean/run execution, executable selection, argument history, persistent project metadata, compiler diagnostics, C helpers, and the NuiComponents project switcher.
- YAP's project switcher and runner use `nui-components.nvim` on top of `nui.nvim`. The switcher provides project search, selection, an optional README preview, and contextual keymap hints. The runner keeps its live operation summary separate from the read-only ANSI-colored process output.
- `lua/soul/plugins/lualine.lua` reads the current project label from `yap.project_registry`; the registry itself is owned by YAP.
- `lua/soul/core/helpers/ui/` owns the editor's palette, highlight groups, shared float borders, output windows, and custom floating-window helpers. YAP uses its own `Yap*` highlight namespace and receives the palette through its plugin setup.

YAP's build workflow is intentionally script-based:

- On Windows it checks `build_all.bat` and then `build.bat`.
- On Unix-like systems it checks `build_all.sh` and then `build.sh`.
- Build-and-run launches `bin/<project-directory-name>` (with `.exe` on Windows).
- Direct binary execution lists executable files in `bin/`, prompts for arguments, and skips the build step.

The main plugin groups are:

- Dashboard and UI: Alpha, minimal Lualine, Everforest, icons
- Navigation: Telescope, YAP project picker, Mini Files, Mini Sessions
- Editing: Mini.ai, Mini.surround, Treesitter, Render Markdown, Colorizer, TODO comments
- Notifications: Mini.notify
- Terminal: ToggleTerm
- Folding: nvim-ufo and statuscol
- Git: Gitsigns
- Completion: Blink.cmp

## LSP and debugging

- `lua/soul/lsp/lsp.lua` owns the active native LSP setup, capabilities, keymaps, and diagnostics.
- `lsp/*.lua` contains server-specific native LSP configurations such as clangd and lua-language-server.
- `lua/soul/lsp/dap.lua` owns the LLDB adapter, project registry, executable selection, launch arguments, REPL helpers, and DAP UI.

The DAP registry is stored in Neovim's state directory, not in the repository. Machine-specific paths should never be committed.

## Platform handling

`lua/soul/core/platform.lua` is the single source of truth for platform detection. It exposes:

- `platform.is_windows`
- `platform.is_linux`
- `platform.is_wsl`
- `platform.is_termux`
- `platform.is_macos`
- `platform.name`

WSL detection checks non-empty WSL environment variables and Linux kernel information (`/proc/version` and `uname`) instead of relying on a Neovim feature flag. WSL is classified separately from native Linux. Detection describes the OS running Neovim, not the filesystem containing the current project. To use the WSL profile, launch this configuration from Neovim installed and running inside the WSL distribution; opening a `\\wsl# Configuration architecture

The entry point is `init.lua`. It loads core settings, registers plugin imports through `GET()`, and then starts Lazy.nvim.

## Core

| Path | Responsibility |
|---|---|
| `lua/soul/launch.lua` | Collect Lazy.nvim imports |
| `lua/soul/lazy.lua` | Bootstrap and configure Lazy.nvim |
| `lua/soul/core/options.lua` | Editor options, shell, clipboard, and UI defaults |
| `lua/soul/core/neovide.lua` | Neovide-only settings |
| `lua/soul/core/keymaps.lua` | Global keymaps and helper options |
| `lua/soul/core/autocmds.lua` | Core autocmds |
| `lua/soul/core/platform.lua` | Centralized operating-system and WSL detection |
| `lua/soul/core/helpers/paths.lua` | Project directory and external tool paths |
| `lua/soul/core/helpers/ui/init.lua` | UI initialization, shared floating-window geometry, and text windows |
| `lua/soul/core/helpers/ui/colors.lua` | Everforest palette and centralized editor/plugin highlight definitions |
| `lua/soul/core/helpers/ui/highlights.lua` | Shared semantic highlight links |
| `lua/soul/core/helpers/ui/floats.lua` | Shared border style, Telescope border glyphs, and float window highlights |

## Plugins

Plugin specifications live under `lua/soul/plugins` and `lua/soul/extras`.

- `lua/soul/plugins/telescope.lua` owns general Telescope setup and pickers.
- `lua/soul/plugins/yap.lua` configures YAP, its project directory, plugin-owned highlight groups, and direct dependencies.
- `soulz3r/yap.nvim` owns C project detection, build/clean/run execution, executable selection, argument history, persistent project metadata, compiler diagnostics, C helpers, and the NuiComponents project switcher.
- YAP's project switcher and runner use `nui-components.nvim` on top of `nui.nvim`. The switcher provides project search, selection, an optional README preview, and contextual keymap hints. The runner keeps its live operation summary separate from the read-only ANSI-colored process output.
- `lua/soul/plugins/lualine.lua` reads the current project label from `yap.project_registry`; the registry itself is owned by YAP.
- `lua/soul/core/helpers/ui/` owns the editor's palette, highlight groups, shared float borders, output windows, and custom floating-window helpers. YAP uses its own `Yap*` highlight namespace and receives the palette through its plugin setup.

YAP's build workflow is intentionally script-based:

- On Windows it checks `build_all.bat` and then `build.bat`.
- On Unix-like systems it checks `build_all.sh` and then `build.sh`.
- Build-and-run launches `bin/<project-directory-name>` (with `.exe` on Windows).
- Direct binary execution lists executable files in `bin/`, prompts for arguments, and skips the build step.

The main plugin groups are:

- Dashboard and UI: Alpha, minimal Lualine, Everforest, icons
- Navigation: Telescope, YAP project picker, Mini Files, Mini Sessions
- Editing: Mini.ai, Mini.surround, Treesitter, Render Markdown, Colorizer, TODO comments
- Notifications: Mini.notify
- Terminal: ToggleTerm
- Folding: nvim-ufo and statuscol
- Git: Gitsigns
- Completion: Blink.cmp

## LSP and debugging

- `lua/soul/lsp/lsp.lua` owns the active native LSP setup, capabilities, keymaps, and diagnostics.
- `lsp/*.lua` contains server-specific native LSP configurations such as clangd and lua-language-server.
- `lua/soul/lsp/dap.lua` owns the LLDB adapter, project registry, executable selection, launch arguments, REPL helpers, and DAP UI.

The DAP registry is stored in Neovim's state directory, not in the repository. Machine-specific paths should never be committed.

## Platform handling

`lua/soul/core/platform.lua` is the single source of truth for platform detection. It exposes:

- `platform.is_windows`
- `platform.is_linux`
- `platform.is_wsl`
- `platform.is_termux`
- `platform.is_macos`
- `platform.name`

 project from Windows Neovim is still the Windows profile.

Platform behavior:

| Platform | Behavior |
|---|---|
| Windows | PowerShell, Windows executable paths, and `.exe` binaries |
| Linux | POSIX shell commands, native Linux binaries, and Neovim's normal clipboard provider |
| WSL | Linux/POSIX build and run commands, Linux binaries and LLDB, plus Windows clipboard interoperability when `clip.exe` and `powershell.exe` or `pwsh.exe` are discoverable in WSL's `PATH` |
| macOS | POSIX build and run commands |

Use `platform.is_*` for OS decisions. Do not repeat raw `vim.fn.has()` checks in feature modules. Keep machine-specific paths and tool lookup in `lua/soul/core/helpers/paths.lua`, not in the platform detector. WSL-specific Windows interop commands are resolved there rather than assumed to exist. When Windows and Linux share behavior, keep the implementation shared while making the platform branch explicit. Platform-sensitive code in this repository is limited to the platform detector, path/tool resolution, editor shell and clipboard setup, the C runner, and DAP executable handling; the remaining UI and plugin configuration should stay OS-neutral.
