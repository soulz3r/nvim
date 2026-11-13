# Performance and resource lifecycle

CVIM treats background work as a resource with an explicit owner and lifetime. The goal is not to unload every Lua module or kill every idle process. The goal is to avoid work that has no active user-facing purpose, while preserving useful state such as clangd's index whenever buffers still depend on it.

## Resource ownership

| Resource | Owner | Activation | Release |
|---|---|---|---|
| Alpha animation timer | `core/helpers/dashboard/animation.lua` | Empty startup with Alpha active | Stop and close on leaving Alpha |
| Dashboard callbacks and frame state | `core/helpers/dashboard/alpha/autocmds.lua` | Alpha setup | Delete its augroup, clear state, and release CVIM dashboard module-cache entries |
| LSP idle timers | `core/lifecycle/lsp.lua` | Last buffer detaches from a client | Cancel on a new attachment, client stop, or Neovim exit |
| LSP process | Neovim's native LSP client | Matching filetype and enabled server | Graceful stop after ten minutes with no loaded attached buffers |
| Project restore | `core/lifecycle/project.lua` | Empty startup with a saved YAP project | One-shot VimEnter callback; no YAP/Telescope load |

`core/lifecycle/scope.lua` provides a small cleanup scope. A scope owns cleanup callbacks, libuv timers, and autocmd groups. Closing it is idempotent and runs cleanup in reverse acquisition order.

## Demand-loaded features

Expensive features are activated at the earliest event that actually needs them:

- DAP and its UI dependencies load on the first debugger mapping.
- Treesitter loads on the first file buffer and requests only that filetype's parsers. Opening an empty Neovim session does not start parser installation.
- Breadcrumbs load when an LSP client attaches.
- Telescope loads when its command is invoked or another feature explicitly depends on it.
- YAP loads on the first file buffer or project action. Its last-project restore is handled by the small core module above, so startup does not need to load YAP or Telescope.
- TODO comments and the folding UI load when a file buffer opens.
- WhichKey and other presentation features that do not need to exist before the first screen are deferred to `VeryLazy`.

The Everforest colorscheme remains eager because the editor needs its colors before rendering the first screen. Session handling also remains early so automatic session read/write behavior is preserved.

## Dashboard lifecycle

Alpha is loaded on `VimEnter` only when Neovim was started without file or directory arguments. Its animation uses a one-shot libuv timer. A new frame is scheduled only after the previous frame update and redraw complete, preventing timer callbacks from accumulating when redraw work takes longer than the configured interval.

When the Alpha buffer is left, CVIM stops and closes the timer, deletes the dashboard autocmd group, drops frame-state references, and clears CVIM's dashboard helper modules from `package.loaded`. Lua garbage collection reclaims objects when no remaining references exist. Alpha's own plugin modules are intentionally not force-unloaded because its commands and internal references may still exist.

## LSP idle shutdown

The LSP lifecycle manager uses a conservative policy:

- A client is considered eligible only when it has no loaded attached buffers.
- Hidden buffers still count as attached. Switching to another window or file does not kill a server that still provides services to an open C buffer.
- After the final detach, a ten-minute timer begins.
- A new attachment cancels the timer.
- When the timer expires, CVIM checks the attachment set again and requests a graceful client shutdown.
- The server remains enabled through Neovim's native `vim.lsp.enable()` configuration, so matching buffers can start it again later.

The default timeout is `10 * 60 * 1000` milliseconds and can be shortened temporarily during manual testing:

```lua
require("soul.core.lifecycle.lsp").idle_timeout = 5000
```

This policy intentionally does not stop clangd merely because the current window is not a C buffer. An open hidden C buffer may still need diagnostics, indexing, and workspace state.

## Benchmark procedure

Record results before and after changes on the same machine, Neovim build, plugin lockfile, and project. Run each startup measurement at least five times and compare the median rather than the best run.

### Startup

PowerShell:

```powershell
1..5 | ForEach-Object {
    $log = Join-Path $env:TEMP "cvim-startup-$_.log"
    nvim --startuptime $log +qa
}
```

Linux/macOS:

```sh
for n in 1 2 3 4 5; do
  nvim --startuptime "/tmp/cvim-startup-$n.log" +qa
done
```

Inspect the final startup total and the slowest sourced scripts in each log. Also use `:Lazy profile` to identify plugin load time. Do not compare a first run that is installing plugins against a warmed run.

### Idle resource use

1. Start CVIM with no file arguments and let the dashboard animate for 15 seconds.
2. Open a file and wait another 15 seconds.
3. Observe Neovim's CPU and memory in Task Manager or the platform's process monitor.
4. After leaving Alpha, CPU use should settle. The dashboard must not continue redrawing.
5. With no LSP-attached buffers, verify that the server exits after the configured timeout.
6. Keep a C buffer open in the background while editing another file. clangd must remain alive.
7. Return to the C buffer and verify completion, diagnostics, formatting, and navigation still work.

Memory values are noisy because the OS allocator and Lua garbage collector do not immediately return every freed page to the operating system. Compare trends across repeated runs, not one instantaneous number.

## Manual lifecycle checks

### Dashboard

1. Run `nvim` with no arguments and confirm Alpha appears.
2. Open a file from the dashboard.
3. Confirm the animation stops immediately and the editor remains responsive.
4. Run this command after leaving Alpha; it should report zero dashboard autocmds:

   ```vim
   :lua local ok, events = pcall(vim.api.nvim_get_autocmds, { group = "SoulAlpha" }); print(ok and #events or 0)
   ```

5. Run `nvim path/to/file` and confirm Alpha does not load.

### Project restore and demand loading

1. Start Neovim without arguments and confirm the last valid YAP project directory is restored.
2. Start Neovim with an explicit file path and confirm CVIM leaves the supplied working directory alone.
3. Before pressing a debugger mapping, check `:Lazy` and confirm nvim-dap is not loaded. Press `<F5>` and confirm it loads.
4. Open a C file and confirm only the C parser set is requested. Opening an empty Neovim session should not start Treesitter parser installation.
5. Run `:Telescope find_files` from an empty session and confirm Telescope loads on demand.

### LSP

1. Open a C file and confirm clangd attaches.
2. Open another non-C file while keeping the C buffer open. clangd should remain running.
3. Close every C/C++ buffer attached to clangd.
4. For a quick test, set the timeout to five seconds with the Lua snippet above before closing the final C buffer.
5. Confirm clangd stops after the timeout using `:lua print(vim.inspect(vim.lsp.get_clients()))`.
6. Open a new C file and verify clangd starts again and all C tooling works.
7. Repeat with a C buffer hidden in another tab. The server should stay alive while that buffer remains attached.

## What this does not claim

These lifecycle changes reduce unnecessary background work. They do not establish that CVIM is faster than NvChad without measurements on the same hardware and workload. Plugin count and repository size are not runtime benchmarks.
