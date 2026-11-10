# soulz3r/nvim

A personal Neovim configuration for **Windows 11** and **Arch Linux** (including Hyprland).

The configuration is built around Lazy.nvim, native Neovim LSP, Blink.cmp, Telescope, Mini Files, Treesitter, custom LLDB debugging, and an Everforest-oriented UI.

> **Target:** Neovim 0.12.x. This configuration uses modern Neovim APIs such as `vim.lsp.config`, `vim.lsp.enable`, and the current Treesitter setup API. Older versions are not a supported target.

## Features

- Lazy.nvim plugin management with automatic bootstrap
- Native Neovim LSP configuration, without Mason
- Blink.cmp completion
- clangd support for C and C++
- Project-aware LLDB DAP configuration and executable discovery
- Per-user DAP project registry stored outside the repository
- Telescope pickers with project-root search and Mini Files with preview and hidden-file controls
- Mini sessions for project session save, restore, and automatic persistence
- Mini.ai text objects, Mini.surround editing, and Mini.notify notifications
- Treesitter highlighting and folding integration
- Project manager powered by Telescope Projects, with project build/run actions and individual-file execution
- ToggleTerm with persistent horizontal, vertical, and floating terminals
- Alpha dashboard with recent files, recent projects, quick actions, and an animated header
- Minimal Lualine statusline with no winbar
- Everforest-oriented highlights and rounded UI
- Windows and Linux path, shell, clipboard, and debugger handling

## Requirements

### Core

- Neovim 0.12.x
- Git
- A Nerd Font
- `ripgrep` (`rg`) for live grep
- `fd` for file discovery
- `make` and a C compiler for `telescope-fzf-native.nvim`

### Language tools

Install the tools you intend to use and make sure they are available on `PATH`:

- `clangd` for C and C++
- `lua-language-server` for Lua
- `bash-language-server` for shell scripts
- `stylua` for Lua formatting and format-on-save
- `lldb-dap` for C/C++ debugging

On Windows, PowerShell 7 (`pwsh`) is used as the configured shell and to run custom `build.bat` project scripts. Linux uses Bash for custom `build.sh` scripts.

The LSP servers and debugger are intentionally installed outside Neovim. **Mason is not used.**

## Installation

Clone this repository into the directory returned by:

```vim
:echo stdpath('config')
```

### Linux

The default Neovim config directory is usually `~/.config/nvim`.

```sh
git clone https://github.com/soulz3r/nvim.git ~/.config/nvim
nvim
```

### Windows

The standard Neovim config directory is usually `%LOCALAPPDATA%\nvim`.

```powershell
git clone https://github.com/soulz3r/nvim.git "$env:LOCALAPPDATA\nvim"
nvim
```

If you use a custom location (for example, `D:\.config\nvim`), clone the repository into that directory instead.

On the first launch, Lazy.nvim bootstraps itself and installs the configured plugins. Then run:

```vim
:Lazy sync
:checkhealth
```

Install the external tools listed above separately. A plugin manager cannot install your system toolchain by telepathy, sadly.

## C and C++ development

clangd reads project build metadata. Prefer a generated `compile_commands.json` when your build system supports it. For small projects, a `compile_flags.txt` in the project root also works.

Example for a C23 project:

```text
-std=c23
-Iinclude
-Isrc
-g
```

Keep the language standard in the project configuration rather than forcing `-std=c23` globally. That lets C++ projects choose their own standard.

The clangd configuration recognizes project markers including:

- `.clangd`
- `.clang-tidy`
- `.clang-format`
- `compile_commands.json`
- `compile_flags.txt`
- `.git`

Useful LSP mappings are documented in [docs/keymaps.md](docs/keymaps.md).

## Debugging with LLDB

The custom DAP configuration uses `lldb-dap` directly. No Mason adapter is required.

The adapter defaults to:

- Windows: `C:/Program Files/LLVM/bin/lldb-dap.exe`
- Linux: `lldb-dap` from `PATH`

Override the executable with the `LLDB_DAP` environment variable if it is installed elsewhere.

The debugger detects project roots from common markers such as `.git`, `CMakeLists.txt`, `Makefile`, `compile_commands.json`, `meson.build`, and `Cargo.toml`. It searches common build directories for executables and also lets you select an executable manually.

See [docs/debugging.md](docs/debugging.md) for setup, mappings, and registry details.

## Environment variables

| Variable | Purpose | Default |
|---|---|---|
| `PROJECTS_DIR` | Base directory for Telescope Projects and project discovery | Windows: `D:/config/projects`; Linux: `~/projects` |
| `LLDB_DAP` | Full path or command name for `lldb-dap` | Windows LLVM path; Linux `lldb-dap` |
| `PWSH` | PowerShell executable on Windows | `pwsh` or `pwsh.exe` |

## Projects

Telescope Projects is the project hub. Use `<leader>fp` to open the picker:

| Key | Action |
|---|---|
| Enter | Change Neovim's working directory to the selected project |
| `Ctrl-r` | Run the selected project |
| `Ctrl-b` | Build the selected project |
| `Ctrl-f` | Find files in the selected project |
| `Ctrl-g` | Live grep in the selected project |

The same project actions are available outside the picker:

- `<leader>rr` runs the current project.
- `<leader>rb` builds the current project.
- `<leader>rf` runs the current file independently. C files are compiled with C23 and debug symbols, then executed; Lua, Python, and JavaScript files use their respective runtimes.

Project detection supports custom `build.bat` / `build.sh` scripts, CMake, Make, Cargo, Go modules, and npm scripts. Build-based projects search common output directories for executables. If multiple executables are found, you can select which one to launch.

`lua/soul/core/projects.lua` contains the project detection and execution logic. It does not depend on Telescope, so project operations can also be called directly from Lua.

## Local DAP state

The DAP registry is runtime state and is not committed to Git. It is stored under:

```text
stdpath("state")/soul/dap-projects.json
```

The configuration can migrate the previous file at `stdpath("config")/lsp/dap-projects.json` when that file is present.

**When upgrading from an older checkout:** back up the old `lsp/dap-projects.json` before switching branches or pulling changes that remove it. Restore the backup at the old path once, start Neovim, and the configuration will migrate it.

## Repository layout

See [docs/architecture.md](docs/architecture.md) for the module map.

## Checks

Run the repository's static checks with:

```sh
bash scripts/check.sh
```

The script validates JSON configuration, checks that local DAP state is not tracked, and catches known stale APIs and plugin references. The separate `.github/workflows/lua-syntax.yml` workflow parses every Lua file with Lua 5.1. These checks do not replace a real Neovim startup test or testing on both Windows and Linux.

## Troubleshooting

- Run `:checkhealth` after installation.
- Run `:Lazy` and check whether plugin installation or compilation failed.
- Make sure `rg`, `fd`, `clangd`, `stylua`, language servers, and `lldb-dap` are visible on `PATH`.
- If DAP cannot start, check `LLDB_DAP` and confirm that the executable exists.
- If C diagnostics are missing or use the wrong standard, check the project's `compile_commands.json` or `compile_flags.txt`.
- If Treesitter highlighting is missing after first install, run `:TSUpdate` and reopen the buffer.

## License

This is a personal configuration repository. Check individual plugin licenses for the software managed by the configuration.
