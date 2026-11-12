# Configuration architecture

The entry point is \`init.lua\`. It loads the core modules, registers plugin groups through \`GET()\`, and starts Lazy.nvim.

## Startup flow

1. \`lua/soul/launch.lua\` initializes the Lazy.nvim import list and defines \`GET()\`.
2. Core paths, options, keymaps, autocmds, UI helpers, and Neovide settings load.
3. \`GET()\` registers plugin groups from \`lua/soul/plugins\`, \`lua/soul/lsp\`, \`lua/soul/cmp\`, and \`lua/soul/extras\`.
4. \`lua/soul/lazy.lua\` bootstraps Lazy.nvim and loads the registered specifications.

## Core modules

| Path | Responsibility |
|---|---|
| \`lua/soul/core/platform.lua\` | Centralized Windows, WSL, Linux, macOS, and Termux detection |
| \`lua/soul/core/helpers/paths.lua\` | Project directory and external tool path resolution |
| \`lua/soul/core/helpers/keymaps.lua\` | Shared options for keymap definitions |
| \`lua/soul/core/helpers/process.lua\` | Child-process timeout, termination, and reaping |
| \`lua/soul/core/helpers/dap/path.lua\` | Shared DAP path normalization, project keys, containment, and executable checks |
| \`lua/soul/core/helpers/dap/project.lua\` | Composes the focused DAP project modules and exposes their public API |
| \`lua/soul/core/helpers/dap/project/store.lua\` | DAP project metadata, executable/argument persistence, and registered-project lookup |
| \`lua/soul/core/helpers/dap/project/registry.lua\` | Independent, atomic DAP project registry under Neovim's state directory |
| \`lua/soul/core/helpers/dap/project/resolver.lua\` | Buffer-aware project-root detection and manual project activation |
| \`lua/soul/core/helpers/dap/project/selection.lua\` | Saved DAP project picker and executable-path selection UI |
| \`lua/soul/core/helpers/dap/launch.lua\` | LLDB adapter, launch configurations, executable selection, and argument prompting |
| \`lua/soul/core/helpers/dap/keymaps.lua\` | DAP session, breakpoint, stepping, evaluation, REPL, and UI mappings |
| \`lua/soul/core/helpers/dap/registry.lua\` | Safe migration of legacy DAP state and one-time import of old DAP fields from YAP's registry |
| \`lua/soul/core/helpers/dap/executables.lua\` | Bounded project executable discovery and ranking |
| \`lua/soul/core/options.lua\` | Editor options, shell, clipboard, and UI defaults |
| \`lua/soul/core/keymaps.lua\` | Global keymaps and shared keymap helpers |
| \`lua/soul/core/autocmds.lua\` | Core autocmds |
| \`lua/soul/core/neovide.lua\` | Neovide-only settings |
| \`lua/soul/core/helpers/ui/init.lua\` | UI initialization, shared floating-window geometry, and text windows |
| \`lua/soul/core/helpers/ui/output.lua\` | Reusable floating output and interactive terminal windows |
| \`lua/soul/core/helpers/ui/colors.lua\` | Everforest palette and editor/plugin highlight definitions |
| \`lua/soul/core/helpers/ui/highlights.lua\` | Shared semantic highlight links |
| \`lua/soul/core/helpers/ui/floats.lua\` | Shared float borders and window highlights |

## Plugin groups and connections

Plugin specifications live under \`lua/soul/plugins\` and \`lua/soul/extras\`.

- \`lua/soul/plugins/mini.lua\` returns the individual Mini plugin specifications. Each specification delegates setup to its matching helper under \`lua/soul/core/helpers/mini/\`; the main config imports the group once with \`GET("soul.plugins.mini")\`.
- \`lua/soul/plugins/alpha.lua\` uses Telescope for file search, Mini Files for browsing, and YAP's project picker for project switching.
- \`lua/soul/plugins/telescope.lua\` owns general Telescope setup and pickers.
- \`lua/soul/plugins/undotree.lua\` lazily loads the Lua Undotree visualizer when \`<leader>u\` is pressed. Mini Files is the sole configured file manager; the unused Oil specification is intentionally absent.
- \`lua/soul/plugins/yap.lua\` configures YAP, its project directory, highlights, and the Telescope project integration.
- \`soulz3r/yap.nvim\` owns C project workflows: project discovery, build/clean/run execution, executable selection, argument history, compiler diagnostics, C helpers, and its Telescope project picker actions.
- \`lua/soul/plugins/lualine.lua\` optionally reads the current project label from \`yap.project_registry\`. It has no hard dependency on YAP and omits the project label when YAP is unavailable.
- \`lua/soul/lsp/dap.lua\` does not depend on YAP. DAP owns its project selection, executable/argument metadata, root resolution, and persistent registry.
- \`lua/soul/plugins/gitsigns.lua\` registers Git mappings with WhichKey.
- \`lua/soul/plugins/breadcrumbs.lua\` configures breadcrumbs.nvim and declares its nvim-lspconfig and nvim-navic dependencies. \`lua/soul/lsp/lsp.lua\` initializes Navic before enabling servers and attaches it to clients that support document symbols.
- LSP capabilities use Blink.cmp when it is available. LSP keymaps are attached per buffer when a server attaches. The LSP attach callback connects nvim-navic to clients that support document symbols, which supplies the context rendered by breadcrumbs.nvim.
- Render Markdown declares Treesitter and Mini Icons as dependencies. Mini Files also declares Mini Icons as a dependency so its icon integration is ready whenever the file browser loads.
- ToggleTerm uses the configured shell and shared float border helpers.

YAP's project picker is provided through \`telescope-project.nvim\`, with runner actions supplied by YAP. YAP's registry stores YAP project metadata and is used by its own project workflows. Lualine may read its project label as an optional integration. DAP uses a separate registry under \`stdpath("state")/soul/dap/projects.json\`; a one-time migration imports existing DAP-specific fields from the former YAP registry without modifying YAP's file. Runner output uses YAP's own Neovim floating-window helpers. Runtime state is stored outside the repository.

## Platform handling

\`lua/soul/core/platform.lua\` is the single source of truth for OS detection. Feature modules should use its \`is_*\` fields instead of repeating raw OS checks.

| Platform | Behavior |
|---|---|
| Windows | PowerShell, Windows executable paths, and \`.exe\` binaries |
| Linux | POSIX build/run commands, native binaries, and the normal Neovim clipboard provider |
| WSL | Linux/POSIX build/run commands and Linux binaries, with Windows clipboard interoperability when the Windows tools are available in WSL's PATH |
| macOS | POSIX build/run commands |

WSL detection uses WSL environment variables and Linux kernel information. It identifies the OS running Neovim, not the filesystem containing the current project. Run Neovim inside the WSL distribution to use the WSL profile; opening a WSL filesystem from Windows Neovim remains the Windows profile.

Machine-specific tool paths belong in \`lua/soul/core/helpers/paths.lua\`. Use \`PROJECTS_DIR\`, \`LLDB_DAP\`, \`PWSH\`, and \`CLANG\` to override the defaults without changing the shared configuration. The C runner and editor shell use the same resolved executable paths.

## LSP and debugging

- \`lua/soul/lsp/lsp.lua\` configures native Neovim LSP capabilities, keymaps, formatting, and diagnostics.
- Server definitions are supplied by nvim-lspconfig and enabled through \`vim.lsp.enable()\`.
- \`lua/soul/lsp/dap.lua\` is intentionally a thin composition layer: it loads the project, launch, UI, and keymap modules.
- \`project.lua\` composes the DAP-owned project registry, root resolver, and selection UI behind one stable public API. \`project/store.lua\` owns DAP metadata reads and writes; \`project/registry.lua\` owns independent JSON persistence; \`project/resolver.lua\` owns buffer-aware root detection and manual activation; and \`project/selection.lua\` owns the project and executable pickers.
- \`launch.lua\` owns LLDB launch configuration and argument parsing/persistence orchestration.
- \`keymaps.lua\` owns the DAP mapping groups; \`ui.lua\` owns DAP UI setup and source-window restoration, while \`repl.lua\` owns REPL discovery, focus, and search.
- \`path.lua\` is the shared normalization/key/containment/executable utility used by project resolution and executable discovery. Argument parsing, registry migration, and bounded executable discovery remain independently testable helpers.

The configuration targets Neovim 0.12 or newer. The optional tiny-cmdline integration is isolated in \`lua/soul/extras/tiny_cmdline.lua\`; it relies on private, experimental UI2 internals and falls back to Neovim's native command line when the required UI2 entry point is unavailable or setup fails. The rest of the configuration does not depend on UI2.
