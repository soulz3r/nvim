# Design decisions

This configuration is intentionally opinionated. The choices below are constraints that keep the setup predictable across Windows, WSL, and Linux, rather than a list of fashionable plugins.

## No Mason

Language servers, formatters, compilers, and the debugger are system tools, not editor plugins. Installing them outside Neovim keeps their versions and paths visible to the operating system, makes the same toolchain usable from a terminal, and avoids a second package-management layer inside the editor. The configuration resolves executables through `PATH` and a small set of explicit environment overrides.

## Neovim 0.12+

The configuration targets the current native LSP model, including `vim.lsp.config()` and `vim.lsp.enable()`, plus current Treesitter APIs and newer core behavior. Supporting older releases would mean maintaining compatibility branches for APIs the configuration does not intend to use. The minimum version is explicit so users do not mistake an unsupported runtime for a plugin failure.

## YAP owns project workflows

YAP is the shared project layer for project discovery, build/run/clean actions, executable selection, argument history, compiler diagnostics, and project metadata. Telescope provides the picker UI, while YAP owns the project behavior. DAP stores its selected executable and launch arguments in YAP's project registry, avoiding separate competing registries for the same project.

## LLDB DAP without an adapter installer

The debugger uses `lldb-dap` directly. LLVM is installed as a normal system tool and can be used independently of Neovim. `LLDB_DAP` allows a machine-specific path without hard-coding another user's installation layout.

## Native LSP configuration

Server definitions live in the repository's `lsp/` directory and are enabled with Neovim's native LSP API. nvim-lspconfig supplies server definitions where useful, but it does not own server installation. Each server is enabled independently so one unavailable configuration does not block the others.

## Cross-platform defaults with explicit overrides

Platform detection and external executable resolution are centralized. The default project directory is `D:/projects` on Windows and `~/projects` on Unix-like systems. `PROJECTS_DIR`, `CLANG`, `PWSH`, and `LLDB_DAP` provide machine-specific overrides without requiring edits to tracked configuration files.

## Keep the UI layer deliberate

Everforest, rounded borders, shared floating-window helpers, and a small set of focused plugins provide a consistent interface. New dependencies should solve a concrete problem; the configuration avoids adding a framework merely to wrap a few existing Neovim APIs.
