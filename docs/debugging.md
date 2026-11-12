# C/C++ debugging

The configuration uses `nvim-dap`, `nvim-dap-ui`, and the LLDB DAP adapter directly. It does not use Mason and has no runtime dependency on YAP.

## Install LLDB DAP

Install LLVM with `lldb-dap` available.

- Windows default: `C:/Program Files/LLVM/bin/lldb-dap.exe`
- Linux default: `lldb-dap` from `PATH`

If the adapter is elsewhere, set `LLDB_DAP` to its full path before launching Neovim.

## Project detection

The current project root is detected from the current buffer using common markers:

- `.git`
- `.clangd`, `.clang-tidy`, and `.clang-format`
- `CMakeLists.txt`
- `Makefile` / `makefile`
- `build.ninja`
- `compile_commands.json` / `compile_flags.txt`
- `meson.build`
- `Cargo.toml`
- `build.sh`, `build.bat`, `build_all.sh`, and `build_all.bat`

DAP also remembers roots for projects that have saved debugger settings. This lookup uses DAP's own registry, not YAP's project list.

Executable discovery checks the project root and common output directories such as `bin/`, `build/`, `build/Debug/`, `build/Release/`, `Debug/`, and `Release/`.

On Windows it looks for `.exe` files. On Linux it checks the executable permission.

## First launch

1. Open a source file inside the project.
2. Build the project with your normal build system.
3. Press `<leader>dc` or `F5`.
4. If one executable is found, it is selected automatically.
5. If multiple executables are found, choose one from the picker.
6. Enter program arguments when prompted.

Use `<leader>de` to select an executable manually. Use `<leader>dp` to switch between projects previously saved in DAP's registry.

The argument prompt supports quoted arguments, spaces, and empty quoted arguments. On Windows, ordinary backslashes in paths are preserved.

## Registry storage

DAP stores its project metadata independently from YAP:

```text
stdpath("state")/soul/dap/projects.json
```

The registry contains only DAP-owned information: saved debugger projects, selected executables, launch arguments, and last-opened timestamps. DAP does not require YAP to be installed or loaded.

### Importing previous settings

On the first startup after the registry separation, DAP imports only its former executable and argument fields from YAP's old registry:

```text
stdpath("state")/yap/projects.json
```

If that file does not exist, the importer checks the older fallback location:

```text
stdpath("state")/soul/projects.json
```

The importer leaves YAP's registry untouched and writes a one-time marker at:

```text
stdpath("state")/soul/dap/yap-registry-imported
```

The marker prevents stale YAP data from overwriting DAP settings on later launches.

Older DAP-only registries are also imported from:

- `stdpath("config")/lsp/dap-projects.json`
- `stdpath("state")/soul/dap-projects.json`

After a successful import, each old DAP-only file is renamed with a `.migrated` suffix. If that backup already exists, a timestamp is appended. If migration fails, the original file is left in place and an error is shown.

### Migration recovery

Do not delete legacy DAP files or their `.migrated` backups until you have checked the saved projects, executables, and launch arguments.

The YAP registry is never moved, renamed, or overwritten by DAP migration. If the one-time YAP import needs to be retried, close Neovim and remove only the migration marker at `stdpath("state")/soul/dap/yap-registry-imported`; the importer will read the still-intact YAP registry again. Do this only after backing up DAP's current registry, because importing legacy values can update matching project entries.

If a DAP-only migration fails, the original legacy file is intentionally left untouched. Fix the reported registry write problem and restart Neovim to retry.

## Useful controls

- `<leader>du` toggles the DAP UI.
- `<leader>dh` evaluates the expression under the cursor or selection.
- `<leader>dR` opens or focuses the REPL.
- `<leader>d/` searches REPL output.
- `<leader>dw` adds a watch expression.
- `<leader>dk` terminates the current session.

See [keymaps.md](keymaps.md) for the complete debugging mapping list.
