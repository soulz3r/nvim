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
- Telescope pickers and Mini Files
- Treesitter highlighting and folding integration
- ToggleTerm with horizontal, vertical, and floating terminals
- Alpha dashboard with a small animated header
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
- `stylua` for Lua formatting
- `lldb-dap` for C/C++ debugging

On Windows, PowerShell 7 (`pwsh`) is used as the configured shell and by the S3D build task. On Linux, the S3D build task uses Bash.

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
| `PROJECTS_DIR` | Base directory for personal projects and the S3D task | Windows: `D:/config/projects`; Linux: `~/projects` |
| `LLDB_DAP` | Full path or command name for `lldb-dap` | Windows LLVM path; Linux `lldb-dap` |
| `PWSH` | PowerShell executable on Windows | `pwsh` or `pwsh.exe` |

The optional S3D build task expects this layout:

```text
$PROJECTS_DIR/
└── s3d/
    ├── engine/
    │   ├── build.bat   # Windows
    │   └── build.sh    # Linux
    ├── testbed/
    │   ├── build.bat   # Windows
    │   └── build.sh    # Linux
    └── bin/
        ├── testbed.exe # Windows
        └── testbed     # Linux
```

Press `<leader>nn` to build the engine, build the testbed, and launch it. This is a personal S3D task, not a generic project builder.

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

The checks compile every Lua file with Lua 5.1's parser and validate the JSON configuration files. They do not replace a real Neovim startup test or testing on both Windows and Linux.

## Troubleshooting

- Run `:checkhealth` after installation.
- Run `:Lazy` and check whether plugin installation or compilation failed.
- Make sure `rg`, `fd`, `clangd`, `stylua`, language servers, and `lldb-dap` are visible on `PATH`.
- If DAP cannot start, check `LLDB_DAP` and confirm that the executable exists.
- If C diagnostics are missing or use the wrong standard, check the project's `compile_commands.json` or `compile_flags.txt`.
- If Treesitter highlighting is missing after first install, run `:TSUpdate` and reopen the buffer.

## License

This is a personal configuration repository. Check individual plugin licenses for the software managed by the configuration.
