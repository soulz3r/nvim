# Configuration architecture

The entry point is `init.lua`. It loads the core modules, registers plugin groups through `GET()`, and starts Lazy.nvim.

## Startup flow

1. `lua/soul/launch.lua` initializes the Lazy.nvim import list and defines `GET()`.
2. Core paths, options, keymaps, autocmds, UI helpers, and Neovide settings load.
3. `GET()` registers plugin groups from `lua/soul/plugins`, `lua/soul/lsp`, `lua/soul/cmp`, and `lua/soul/extras`.
4. `lua/soul/lazy.lua` bootstraps Lazy.nvim and loads the registered specifications.

## Core modules

| Path | Responsibility |
|---|---|
| `lua/soul/core/platform.lua` | Centralized Windows, WSL, Linux, macOS, and Termux detection |
| `lua/soul/core/helpers/paths.lua` | Project directory and external tool path resolution |
| `lua/soul/core/options.lua` | Editor options, shell, clipboard, and UI defaults |
| `lua/soul/core/keymaps.lua` | Global keymaps and shared keymap helpers |
| `lua/soul/core/autocmds.lua` | Core autocmds |
| `lua/soul/core/neovide.lua` | Neovide-only settings |
| `lua/soul/core/helpers/ui/init.lua` | UI initialization, shared floating-window geometry, and text windows |
| `lua/soul/core/helpers/ui/output.lua` | Reusable floating output and interactive terminal windows |
| `lua/soul/core/helpers/ui/colors.lua` | Everforest palette and editor/plugin highlight definitions |
| `lua/soul/core/helpers/ui/highlights.lua` | Shared semantic highlight links |
| `lua/soul/core/helpers/ui/floats.lua` | Shared float borders and window highlights |

## Plugin groups and connections

Plugin specifications live under `lua/soul/plugins` and `lua/soul/extras`.

- `lua/soul/plugins/mini/init.lua` returns the Mini.nvim plugin specifications from the `mini/` directory. The main config imports the group once with `GET("soul.plugins.mini")`.
- `lua/soul/plugins/alpha.lua` uses Telescope for file search, Mini Files for browsing, and YAP's project picker for project switching.
- `lua/soul/plugins/telescope.lua` owns general Telescope setup and pickers.
- `lua/soul/plugins/yap.lua` configures YAP, its project directory, highlights, and direct UI dependencies.
- `soulz3r/yap.nvim` owns C project detection, build/clean/run execution, executable selection, argument history, project metadata, compiler diagnostics, C helpers, and the NuiComponents project switcher.
- `lua/soul/plugins/lualine.lua` reads the current project label from `yap.project_registry`; YAP is declared as a dependency so the registry is available before the statusline uses it.
- `lua/soul/lsp/dap.lua` also depends on YAP because it shares project executable metadata through `yap.project_registry`.
- `lua/soul/plugins/gitsigns.lua` registers Git mappings with WhichKey.
- `lua/soul/plugins/breadcrumbs.lua` configures breadcrumbs.nvim and declares its nvim-lspconfig and nvim-navic dependencies. `lua/soul/lsp/lsp.lua` initializes Navic before enabling servers and attaches it to clients that support document symbols.
- LSP capabilities use Blink.cmp when it is available. LSP keymaps are attached per buffer when a server attaches. The LSP attach callback connects nvim-navic to clients that support document symbols, which supplies the context rendered by breadcrumbs.nvim.
- Render Markdown depends on Treesitter and Mini Icons. Mini Files depends on Mini Icons.
- ToggleTerm uses the configured shell and shared float border helpers.

YAP's project switcher and runner use `nui-components.nvim` on top of `nui.nvim`. Its project registry is shared by the project picker, Lualine, and DAP. The registry and other runtime state are stored outside the repository.

## Platform handling

`lua/soul/core/platform.lua` is the single source of truth for OS detection. Feature modules should use its `is_*` fields instead of repeating raw OS checks.

| Platform | Behavior |
|---|---|
| Windows | PowerShell, Windows executable paths, and `.exe` binaries |
| Linux | POSIX build/run commands, native binaries, and the normal Neovim clipboard provider |
| WSL | Linux/POSIX build/run commands and Linux binaries, with Windows clipboard interoperability when the Windows tools are available in WSL's PATH |
| macOS | POSIX build/run commands |

WSL detection uses WSL environment variables and Linux kernel information. It identifies the OS running Neovim, not the filesystem containing the current project. Run Neovim inside the WSL distribution to use the WSL profile; opening a WSL filesystem from Windows Neovim remains the Windows profile.

Machine-specific tool paths belong in `lua/soul/core/helpers/paths.lua`. Use `PROJECTS_DIR`, `LLDB_DAP`, `PWSH`, and `CLANG` to override the defaults without changing the shared configuration. The C runner and editor shell use the same resolved executable paths.

## LSP and debugging

- `lua/soul/lsp/lsp.lua` configures native Neovim LSP capabilities, keymaps, formatting, and diagnostics.
- Server definitions are supplied by nvim-lspconfig and enabled through `vim.lsp.enable()`.
- `lua/soul/lsp/dap.lua` configures the LLDB DAP adapter, project-aware executable selection, launch arguments, REPL helpers, and DAP UI.

The configuration targets Neovim 0.12.x. The tiny-cmdline integration is conditional on Neovim 0.12 because it relies on the native UI2 system.
