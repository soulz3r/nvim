# Compatibility and update policy

## Supported runtime

- **Neovim:** 0.12 or newer.
- **Neovide:** 0.16 or newer is recommended for the complete GUI configuration. Settings are isolated in `lua/soul/core/neovide.lua` and use documented options, including options introduced in Neovide 0.14 and 0.16. Terminal Neovim does not depend on Neovide.
- **Platforms:** Windows, WSL, Linux, macOS, and Termux where the required external tools are available.

The configuration checks its Neovim minimum at startup and stops with a clear error on older versions rather than failing later on a missing API.

## Compatibility checks

The GitHub Actions workflow tests the latest Neovim stable release and nightly build on Windows and Linux, and the stable release on macOS. It runs:

1. Lua 5.1 syntax parsing for every repository Lua file.
2. JSON validation for the plugin lockfile and LuaLS settings.
3. A static scan for known deprecated Neovim APIs.
4. A static rule that keeps private Neovim APIs out of the core configuration.
5. A headless Neovim smoke test that loads core modules and every plugin specification without bootstrapping plugins or accessing the network.
6. Native LSP configuration registration for both clangd and lua-language-server (lua_ls), without requiring either server binary on the CI runner.
7. A headless integration test for the custom DAP setup and floating-output window lifecycle, using controlled stubs for external plugin APIs.
8. DAP path and project-resolution tests for normalization, containment, registered ancestors, and file-directory fallback.
9. A full-repository StyLua formatting check.

These checks catch syntax errors, removed core APIs, broken module imports, and regressions in the configuration's integration contracts. They cannot prove that every external plugin, language server, terminal, clipboard provider, debugger installation, or graphical Neovide session works. Those still need real-world testing on the platforms actually used.

## Experimental UI2 integration

Neovim UI2 is experimental and the integration used by tiny-cmdline currently requires the private `vim._core.ui2` module. This is the only intentional private-API exception in the configuration.

The dependency is isolated in `lua/soul/extras/tiny_cmdline.lua`:

- It is loaded only when the UI2 entry point is available.
- Setup is protected with `pcall`.
- If the module or setup is unavailable, `cmdheight` is restored to 1 and Neovim's native command line remains the fallback.
- No other module should access `vim._*` or depend on UI2 internals.

A future Neovim release can still change UI2 internals. If that happens, the custom command-line frontend may be disabled while the rest of the configuration continues to work.

## Plugin updates

`lazy-lock.json` records the exact plugin revisions used by the configuration. Keep it committed and update dependencies deliberately:

1. Run `:Lazy update`.
2. Review the changed plugin revisions and any breaking-change notes.
3. Run `bash scripts/check.sh`.
4. Restart Neovim and test the affected features.
5. Commit the configuration and lockfile together.

Do not remove the lockfile or silently track plugin branches without a lock. A lockfile does not prevent upstream API changes, but it makes updates reproducible and lets you identify which dependency changed.

## Manual checks after upgrades

After updating Neovim, test:

- Startup, command line, notifications, and floating windows.
- LSP attach, diagnostics, formatting, and progress notifications.
- Treesitter highlighting and folds.
- DAP launch, breakpoints, REPL, and DAP UI.
- Telescope, Mini Files, sessions, and project workflows.
- Terminal launch and the C/YAP build-run workflow on each OS you use.
- Neovide startup, font, transparency, window corners, shadows, and cursor/scroll animations.

Neovide is a graphical application and is not exercised by the headless CI workflow. Check its official configuration documentation when changing Neovide versions: https://neovide.dev/configuration.html
