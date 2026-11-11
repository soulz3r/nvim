# soulz3r/nvim

A personal Neovim configuration for **Windows 11**, **WSL**, and **Linux** (including Arch Linux and Hyprland).

The configuration is built around Lazy.nvim, native Neovim LSP, Blink.cmp, Telescope, Mini Files, Treesitter, custom LLDB debugging, and an Everforest-oriented UI.

> **Target:** Neovim 0.12 or newer. This configuration uses modern Neovim APIs such as `vim.lsp.config`, `vim.lsp.enable`, and the current Treesitter setup API. Older versions are not a supported target.

## Features

- Lazy.nvim plugin management with automatic bootstrap
- Native Neovim LSP configuration, without Mason
- Blink.cmp completion
- clangd support for C and C++
- Project-aware LLDB DAP configuration and executable discovery
- Shared project metadata for last executable, arguments, and project activity
- Project actions hub for build, run, clean, and executable selection
- C/C++ helpers for source-header switching, include insertion, and compile metadata
- Per-user DAP project registry stored outside the repository
- Telescope pickers with project-root search and Mini Files with preview and hidden-file controls
- Mini sessions for project session save, restore, and automatic persistence
- Mini.ai text objects, Mini.surround editing, and Mini.notify notifications
- Treesitter highlighting and folding integration
- A floating single-file C23 compile/run terminal across Windows, WSL, and Linux
- YAP project workflows with a component-based runner, live build/run summary, and ANSI-colored process output
- ToggleTerm with persistent horizontal, vertical, and floating terminals
- Alpha dashboard with recent files, recent projects, quick actions, and an animated header
- LSP-aware breadcrumbs in the winbar
- Minimal context-aware Lualine statusline with project and LSP indicators
- Shared floating-window helpers and centralized Everforest palette/highlights
- Consistent rounded borders and transparent float backgrounds across editor and plugin UI
- Windows, WSL, and Linux path, shell, clipboard, compiler, and debugger handling

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

C project build scripts are launched with `cmd.exe` on Windows and `bash` (falling back to `sh`) on Unix-like systems.

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

### WSL

Install Neovim inside the WSL distribution, then clone the same repository into that distribution's `~/.config/nvim`:

```sh
git clone https://github.com/soulz3r/nvim.git ~/.config/nvim
nvim
```

WSL Neovim uses Linux binaries and POSIX build/run commands. To share a Windows project directory, set `PROJECTS_DIR` to its mounted path, for example `/mnt/d/config/projects`. Windows clipboard integration is enabled when `clip.exe` and PowerShell are available in WSL's `PATH`.

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
| `PROJECTS_DIR` | Base directory for YAP project picker and project discovery | Windows: `D:/config/projects`; Linux: `~/projects` |
| `LLDB_DAP` | Full path or command name for `lldb-dap` | Windows LLVM path; Linux `lldb-dap` |
| `PWSH` | PowerShell executable used by the configured shell and C runner | `pwsh` or `pwsh.exe` |
| `CLANG` | Clang executable used by the C compile/run keymap | `clang` from `PATH` |

## Projects

YAP owns the C project workflow and its NuiComponents interface. Use `<leader>pp` to open the C project switcher. Select a project to change Neovim's working directory to that project and close the picker.

The picker discovers C projects from the YAP registry and immediate subdirectories of `PROJECTS_DIR`. It uses a NuiComponents input, selectable project list, optional README preview, and contextual keymap hints. Telescope remains installed for the other pickers in this Neovim configuration.

| Key | Action |
|---|---|
| `<leader>pp` | Open YAP C project switcher |
| `<leader>pr` | Build and run the current project, then enter arguments |
| `<leader>pb` | Build the current project |
| `<leader>pc` | Clean the current project |
| `<leader>pB` | Clean and rebuild the current project |
| `<leader>pS` | Choose a build script |
| `<leader>pe` | Select an executable from `bin/` and run it with arguments |
| `<leader>ps` | Stop the active project process |
| `<leader>pR` | Rerun the most recently used executable and saved arguments |
| `<leader>pq` | Extract compiler diagnostics into the quickfix list |

The runner opens a component-based floating window with a live operation summary, per-step status and duration, and a separate ANSI-colored process-output pane. The output is read-only; press `q` or `Esc` to close it, `Ctrl-c` to stop a running process, and `<leader>pq` to open parsed diagnostics.

YAP's direct UI dependencies are `nui.nvim` and `nui-components.nvim`, declared in `lua/soul/plugins/yap.lua`.

## Local DAP state

The DAP registry is runtime state and is not committed to Git. It is stored under:

```text
stdpath("state")/soul/dap-projects.json
```

The configuration can migrate the previous file at `stdpath("config")/lsp/dap-projects.json` when that file is present.

**When upgrading from an older checkout:** back up the old `lsp/dap-projects.json` before switching branches or pulling changes that remove it. Restore the backup at the old path once, start Neovim, and the configuration will migrate it.

## Repository layout

See [docs/architecture.md](docs/architecture.md) for the module map and [docs/development.md](docs/development.md) for project metadata, C helpers, and UI conventions.

## Compatibility

This configuration targets **Neovim 0.12 or newer**. The compatibility workflow checks the latest Neovim stable release and nightly build on every push and pull request.

The main configuration uses public Neovim APIs. The only private API dependency is the optional tiny-cmdline integration, which uses experimental UI2. If UI2 is unavailable or its setup fails, the configuration keeps Neovim's native command line enabled. See [docs/compatibility.md](docs/compatibility.md) for the support policy and update procedure.

Neovide settings are kept in one module and use documented Neovide options. The CI workflow cannot exercise the graphical frontend, so verify the Neovide UI after upgrading Neovide itself.

## Checks

Run the repository's static checks with:

```sh
bash scripts/check.sh
```

The script validates JSON configuration and repository hygiene, and runs optional Lua syntax and Neovim module smoke tests when those tools are installed. The separate `.github/workflows/lua-syntax.yml` workflow parses every Lua file with Lua 5.1. These checks do not replace a real Neovim startup test or testing on both Windows and Linux.

## Troubleshooting

- Run `:checkhealth` after installation.
- Run `:Lazy` and check whether plugin installation or compilation failed.
- Make sure `rg`, `fd`, `clangd`, `stylua`, language servers, and `lldb-dap` are visible on `PATH`.
- If DAP cannot start, check `LLDB_DAP` and confirm that the executable exists.
- If C diagnostics are missing or use the wrong standard, check the project's `compile_commands.json` or `compile_flags.txt`.
- If Treesitter highlighting is missing after first install, run `:TSUpdate` and reopen the buffer.

## License

This is a personal configuration repository. Check individual plugin licenses for the software managed by the configuration.
