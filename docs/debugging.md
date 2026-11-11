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

DAP project metadata is stored in YAP's shared runtime registry:

```text
stdpath("state")/yap/projects.json
```

The registry stores the project marker and selected debugger executable alongside YAP's project metadata. This avoids maintaining two separate registries for the same projects.

On startup, older DAP-only registries are imported from:

- `stdpath("config")/lsp/dap-projects.json`
- `stdpath("state")/soul/dap-projects.json`

After a successful import, the old file is renamed with a `.migrated` suffix. If that backup already exists, a timestamp is appended. The original settings remain available in that backup. If migration fails, the old file is left in place and an error is shown.
## Useful controls

- `<leader>du` toggles the DAP UI.
- `<leader>dh` evaluates the expression under the cursor or selection.
- `<leader>dR` opens or focuses the REPL.
- `<leader>d/` searches REPL output.
- `<leader>dw` adds a watch expression.
- `<leader>dk` terminates the current session.

See [keymaps.md](keymaps.md) for the complete debugging mapping list.
