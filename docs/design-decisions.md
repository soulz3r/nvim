# Design decisions

This configuration is intentionally opinionated. The choices below are constraints that keep the setup predictable across Windows, WSL, and Linux, rather than a list of fashionable plugins.

## No Mason

Language servers, formatters, compilers, and the debugger are system tools, not editor plugins. Installing them outside Neovim keeps their versions and paths visible to the operating system, makes the same toolchain usable from a terminal, and avoids a second package-management layer inside the editor. The configuration resolves executables through `PATH` and a small set of explicit environment overrides.

## Neovim 0.12+

The configuration targets the current native LSP model, including `vim.lsp.config()` and `vim.lsp.enable()`, plus current Treesitter APIs and newer core behavior. Supporting older releases would mean maintaining compatibility branches for APIs the configuration does not intend to use. The minimum version is explicit so users do not mistake an unsupported runtime for a plugin failure.

## YAP owns project workflows

YAP owns the interactive project workflow: project discovery and switching, build/run/clean actions, executable selection, argument history, compiler diagnostics, C helpers, and its Telescope project picker. Its registry stores YAP project metadata. Other parts of the configuration may integrate with YAP, but they must not depend on it unless they are specifically part of the YAP project workflow.

## DAP owns debugger state

DAP has its own project registry at `stdpath("state")/soul/dap/projects.json`. It independently resolves project roots, selects debug executables, and persists launch arguments. DAP does not depend on YAP's Lua modules or registry, so debugging remains available if YAP is disabled or replaced.

A one-time importer copies only existing DAP-specific executable and argument fields from the former YAP registry into the DAP registry. It leaves YAP's project data untouched and does not create a runtime dependency.

## Optional statusline integrations

Lualine may display YAP's current project label when YAP is available. That display is optional: Lualine itself does not declare YAP as a dependency, and the statusline remains functional without the project component.

## LLDB DAP without an adapter installer

The debugger uses `lldb-dap` directly. LLVM is installed as a normal system tool and can be used independently of Neovim. `LLDB_DAP` allows a machine-specific path without hard-coding another user's installation layout.

## Native LSP configuration

Server definitions live in the repository's `lsp/` directory and are enabled with Neovim's native LSP API. nvim-lspconfig supplies server definitions where useful, but it does not own server installation. Each server is enabled independently so one unavailable configuration does not block the others.

## Cross-platform defaults with explicit overrides

Platform detection and external executable resolution are centralized. The default project directory is `~/projects` on every platform, so the configuration does not assume a particular Windows drive letter. `PROJECTS_DIR`, `CLANG`, `PWSH`, and `LLDB_DAP` provide machine-specific overrides without requiring edits to tracked configuration files.

## Keep the UI layer deliberate

Everforest, rounded borders, shared floating-window helpers, and a small set of focused plugins provide a consistent interface. New dependencies should solve a concrete problem; the configuration avoids adding a framework merely to wrap a few existing Neovim APIs.
