# C/C++ debugging

The configuration uses `nvim-dap`, `nvim-dap-ui`, and the LLDB DAP adapter directly. It does not use Mason.

## Install LLDB DAP

Install LLVM with `lldb-dap` available.

- Windows default: `C:/Program Files/LLVM/bin/lldb-dap.exe`
- Linux default: `lldb-dap` from `PATH`

If the adapter is elsewhere, set `LLDB_DAP` to its full path before launching Neovim.

## Project detection

The current project root is detected from the current buffer using common markers:

- `.git`
- `CMakeLists.txt`
- `Makefile` / `makefile`
- `build.ninja`
- `compile_commands.json`
- `meson.build`
- `Cargo.toml`

Executable discovery checks the project root and common output directories such as `bin/`, `build/`, `build/Debug/`, `build/Release/`, `Debug/`, and `Release/`.

On Windows it looks for `.exe` files. On Linux it checks the executable permission.

## First launch

1. Open a source file inside the project.
2. Build the project with your normal build system.
3. Press `<leader>dc` or `F5`.
4. If one executable is found, it is selected automatically.
5. If multiple executables are found, choose one from the picker.
6. Enter program arguments when prompted.

Use `<leader>de` to select an executable manually. Use `<leader>dp` to switch between saved projects.

The argument prompt supports quoted arguments, spaces, and empty quoted arguments. On Windows, ordinary backslashes in paths are preserved.

## Registry storage

Project roots and executable paths are saved outside the repository at:

```text
stdpath("state")/soul/dap-projects.json
```

The registry writer uses a temporary file and rename so an interrupted write is less likely to corrupt the saved state.

Older configurations stored the registry at `stdpath("config")/lsp/dap-projects.json`. If upgrading from that layout, back up the old file before switching to a branch that removes it from Git. Restore the backup to the old location once after updating; the configuration will migrate it automatically.

## Useful controls

- `<leader>du` toggles the DAP UI.
- `<leader>dh` evaluates the expression under the cursor or selection.
- `<leader>dR` opens or focuses the REPL.
- `<leader>d/` searches REPL output.
- `<leader>dw` adds a watch expression.
- `<leader>dk` terminates the current session.

See [keymaps.md](keymaps.md) for the complete debugging mapping list.
