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
| `lua/soul/core/paths.lua` | Platform detection and external tool paths |
| `lua/soul/ui/init.lua` | UI initialization, shared floating-window geometry, and text windows |
| `lua/soul/ui/colors.lua` | Everforest palette and centralized editor/plugin highlight definitions |
| `lua/soul/ui/highlights.lua` | Shared semantic highlight links |
| `lua/soul/ui/floats.lua` | Shared border style, Telescope border glyphs, and float window highlights |

## Plugins

Plugin specifications live under `lua/soul/plugins` and `lua/soul/extras`.

- `lua/soul/plugins/telescope.lua` owns general Telescope setup and pickers.
- `lua/soul/plugins/yap.lua` configures YAP, its project directory, plugin-owned highlight groups, and direct dependencies.
- `soulz3r/yap.nvim` owns C project detection, build/clean/run execution, executable selection, argument history, persistent project metadata, compiler diagnostics, C helpers, and the NuiComponents project switcher.
- YAP's project switcher and runner use `nui-components.nvim` on top of `nui.nvim`. The switcher provides project search, selection, an optional README preview, and contextual keymap hints. The runner keeps its live operation summary separate from the read-only ANSI-colored process output.
- `lua/soul/plugins/lualine.lua` reads the current project label from `yap.project_registry`; the registry itself is owned by YAP.
- `lua/soul/ui/` owns the editor's palette, highlight groups, shared float borders, and custom floating-window helpers. YAP uses its own `Yap*` highlight namespace and receives the palette through its plugin setup.

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

`lua/soul/core/paths.lua` centralizes Windows/Linux detection and the paths for PowerShell, LLDB, and the projects directory. Keep OS-specific decisions there rather than scattering hard-coded paths throughout plugin files.
