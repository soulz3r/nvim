# soulz3r/nvim

A modular Neovim configuration for Windows and Linux, built around Lazy.nvim, Blink completion, native LSP, LLDB debugging, and an Everforest-oriented UI.

## Requirements

- **Neovim 0.12+**. The command-line UI uses Neovim's experimental UI2 feature.
- Git.
- A Nerd Font for the icons.
- **ripgrep** and **fd** for Telescope search.
- A C compiler and **make** for Treesitter parsers and the Telescope FZF native extension.
- A shell for the build runner:
  - Windows: PowerShell 7 (**pwsh**).
  - Linux: Bash.
- Optional language tools:
  - **clangd**: C and C++ language server.
  - **lldb-dap**: C/C++/Rust debugging adapter.
  - **lua-language-server**: Lua language server.
  - **bash-language-server**: Bash language server.
  - **stylua**: Lua formatter.

The language servers and debugger are external programs. This configuration does not install them through Mason.

## Installation

### Linux

Clone the repository to Neovim's config directory:

    git clone https://github.com/soulz3r/nvim ~/.config/nvim

### Windows (PowerShell)

Clone it to Neovim's default config directory:

    git clone https://github.com/soulz3r/nvim "$env:LOCALAPPDATA/nvim"

If you use a custom Neovim config directory, clone the repository there instead.

Start Neovim. The configuration bootstraps Lazy.nvim on the first launch. Then run:

    :Lazy sync
    :checkhealth

The committed lazy-lock.json pins plugin revisions. Use :Lazy sync to install the pinned plugins and :Lazy update when you intentionally want to update them.

## Environment variables

The following variables let you override machine-specific paths without editing the Lua config.

| Variable | Purpose | Default |
| --- | --- | --- |
| PROJECTS_DIR | Root directory for personal projects | D:/config/projects on Windows; ~/projects elsewhere |
| PWSH | PowerShell executable used by the Windows build runner | pwsh or pwsh.exe |
| LLDB_DAP | LLDB DAP adapter executable | C:/Program Files/LLVM/bin/lldb-dap.exe on Windows; lldb-dap elsewhere |

The S3D build helper expects PROJECTS_DIR/s3d (or ~/projects/s3d on Linux when PROJECTS_DIR is unset). It builds the engine and testbed in sequence.

## C and C++ support

clangd reads compiler flags from the project build system. For a small C project, create a compile_flags.txt in the project root with one flag per line:

    -std=c23
    -Iinclude
    -Isrc

Use -std=c++23 for a C++ project. If compile_commands.json is present, clangd uses that compilation database instead of compile_flags.txt.

## Debugging

The DAP configuration uses lldb-dap directly. It does not require Mason or codelldb.

Project roots are detected from common markers such as .git, .clangd, CMakeLists.txt, Makefile, compile_commands.json, and compile_flags.txt.

When starting a debug session, the configuration searches for executables in:

- bin/
- build/, build/Debug/, and build/Release/
- Debug/ and Release/
- The project root

If more than one executable is found, choose the one to launch. You can also set its full path manually. The project registry is stored under stdpath('state')/soul/dap-projects.json.

### Debug keymaps

| Key | Action |
| --- | --- |
| F5 | Start or continue debugging |
| F9 | Toggle breakpoint |
| F10 | Step over |
| F11 | Step into |
| F12 | Step out |
| <leader>dc | Start/continue and enter program arguments |
| <leader>de | Set the executable path |
| <leader>dp | Select a saved project |
| <leader>du | Toggle the DAP UI |

## Structure

- lua/soul/core/: editor options, keymaps, autocmds, paths, terminal/build helpers, and Neovide settings.
- lua/soul/plugins/: plugin specifications and UI integrations.
- lua/soul/lsp/: LSP and DAP configuration.
- lua/soul/extras/: optional appearance and editing plugins.
- lsp/: Neovim's per-server LSP configuration files.

## Validation

GitHub Actions checks the Lua syntax of every Lua source file with luac -p. This catches syntax errors; it does not replace testing the configuration inside Neovim on each target operating system.
