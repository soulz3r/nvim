# Manual integration test procedure

These checks complement CI. They exercise real plugins and external tools that headless tests intentionally stub.

## Common setup

1. Run `:Lazy sync` and wait for plugin installation/build tasks to finish.
2. Run `:checkhealth`.
3. Open a project containing a small executable and a debug-symbol-enabled build.
4. Record the OS, Neovim version, plugin revisions, and external tool versions when reporting a failure.

## Telescope and fzf-native

1. Run `:Lazy build telescope-fzf-native.nvim`.
2. Confirm the build creates the platform library (`libfzf.dll` on Windows, `libfzf.so` on Linux).
3. Open `:Telescope find_files` and `:Telescope live_grep`; verify fuzzy sorting works.
4. If native loading fails, confirm Telescope displays a warning and its non-native picker remains usable.
5. Exercise the fallback paths in separate clean plugin checkouts: first make CMake configuration/build fail while Make succeeds; then make CMake and Make unavailable while LLVM Clang is available. Confirm a failed CMake attempt is cleaned before Make starts, and a failed cleanup stops the build instead of reusing stale output.
6. Restore the normal PATH after each test and rebuild from a clean plugin directory.

## Real DAP session

1. Install LLVM with `lldb-dap` available and verify `LLDB_DAP` points to it when the default is not correct.
2. Build a small C/C++ program with debug symbols.
3. Set a breakpoint, launch with no arguments, then launch with quoted arguments and paths containing spaces.
4. Verify arguments persist for the project and that selecting a different project restores its own executable and arguments.
5. Close the original source window during a session, then terminate the session. Confirm DAP UI cleanup does not attempt to restore a closed window.
6. Confirm the debugger does not open unrelated source files automatically.

## PowerShell on Windows

1. Launch Neovim from PowerShell 7 and verify the inherited `PSHOME` executable is selected.
2. Set `PWSH` to a nonexistent path and verify discovery falls back to a valid PowerShell 7 installation.
3. Set `PSHOME` to an invalid directory and verify it is ignored.
4. If both PowerShell 7 and Windows PowerShell 5.1 are installed, verify 5.1 is rejected.
5. Test a PowerShell installation path containing spaces.
6. In a disposable Windows VM with PowerShell 7 absent but Windows PowerShell 5.1 present, verify the resolver returns the documented `pwsh` fallback instead of selecting 5.1. The normal resolver also scans standard installation directories, so removing only the PATH entry is not a valid absence test.
7. Restore environment variables and PATH after testing.

## Performance lifecycle

- Start Neovim with no arguments and confirm the last valid YAP project directory is restored while Alpha appears.
- Start Neovim with an explicit file path and confirm CVIM does not override the supplied working directory.
- Before using a debugger, verify nvim-dap and DAP UI are not loaded. Press a DAP mapping and verify they load and work.
- Open a file and confirm Treesitter installs only the parser set for that filetype. Opening an empty session should not trigger parser installation.

## Performance lifecycle

1. Start `nvim` with no arguments, wait for the dashboard, then open a file. Confirm its animation stops and the dashboard autocmd group is removed.
2. Start `nvim path/to/file`; Alpha should not load.
3. Open a C file and verify clangd attaches. Keep that buffer hidden in another tab while editing a non-C file; clangd must remain alive.
4. Close all C/C++ buffers. For a short test, set `require("soul.core.lifecycle.lsp").idle_timeout = 5000` before closing the final buffer. Confirm clangd exits after the timeout.
5. Open a new C file and verify clangd starts again and diagnostics, completion, formatting, and navigation work.
6. Compare at least five startup samples and record idle CPU/memory before and after. Follow the repeatable procedure in [performance.md](performance.md).

## UI and platform smoke tests

- Mini Files: preview, hidden files, directory navigation, working-directory change, destructive-operation confirmation, and synchronization mapping.
- Mini Notify: simultaneous LSP progress from two clients, completion of one client while the other remains active, and client detach.
- ToggleTerm: open, reuse, close, and reopen horizontal, vertical, and floating terminals.
- Clipboard: copy and paste from Neovim using the platform's configured provider.
- Neovide: startup, font, transparency, borders, cursor/scroll behavior, and window lifecycle.

## Platform coverage

Run only the relevant rows on machines you have available. A skipped platform is untested, not passed.

| Platform | Checks |
|---|---|
| Windows | PowerShell 7, LLDB DAP, C build/run, fzf-native DLL build/load, clipboard, ToggleTerm |
| WSL | POSIX shell/compiler, Windows clipboard bridge, mounted project paths, LLDB DAP |
| Linux | Native shell/compiler, clipboard, LLDB DAP, fzf-native build/load, Mini Files and terminal behavior |
| macOS | POSIX shell, available compiler/debugger, clipboard, C build/run |
| Termux | Platform detection, available shell/compiler, project paths, terminal behavior |
| Neovide | GUI startup and visual/window behavior |

The GitHub matrix currently tests stable and nightly Neovim on Windows and Linux, and stable Neovim on macOS. macOS nightly is intentionally omitted until it provides enough additional signal to justify another matrix leg.
