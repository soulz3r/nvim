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
| `lua/soul/plugins/yap.lua` | Configures the pre-nui-components YAP project runner and its floating UI |
| `lua/soul/core/colors.lua` | Colorscheme and highlight setup |

## Plugins

Plugin specifications live under `lua/soul/plugins` and `lua/soul/extras`.

- `lua/soul/plugins/telescope.lua` owns general Telescope setup and pickers.
- `lua/soul/plugins/projects.lua` owns the Telescope Projects picker and project-specific actions/keymaps.
- `soulz3r/yap.nvim` owns project detection, build-script execution, binary launching, run history, and the floating output UI.
- `lua/soul/plugins/projects.lua` keeps the config-specific Telescope project picker and keymaps, while delegating execution to `yap.projects`.

The project runner is intentionally narrow:

- On Windows it checks for `build_all.bat` and then `build.bat`; it can also use the shell scripts when present.
- On Unix-like systems it checks for `build_all.sh` and then `build.sh`.
- Build-and-run executes the script, then launches `bin/<project-directory-name>` (with `.exe` on Windows).
- Direct binary execution lists executable files in `bin/`, prompts for arguments, and skips the build step.

The main plugin groups are:

- Dashboard and UI: Alpha, minimal Lualine, Everforest, icons
- Navigation: Telescope, Telescope Projects, Mini Files, Mini Sessions
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
