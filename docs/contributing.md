# Contributing and maintenance

This is a personal configuration, but changes should preserve the same standards as a small software project. Prefer narrow, reviewable changes over broad formatting or architecture rewrites.

## Before changing code

1. Read [architecture.md](architecture.md) to find the owning module.
2. Read [plugin-inventory.md](plugin-inventory.md) before adding or removing a plugin.
3. Check [compatibility.md](compatibility.md) before using a new Neovim API.
4. Keep platform-specific executable resolution in `lua/soul/core/helpers/paths.lua` and OS detection in `lua/soul/core/platform.lua`.
5. Keep plugin specifications declarative. Put reusable setup in the matching helper rather than coupling helpers to Lazy.nvim.

## Local validation

Run the full repository checks from the repository root:

```sh
bash scripts/check.sh
```

When available, also run:

```sh
stylua --check .
nvim --headless --clean -u NONE -l scripts/check-nvim.lua
nvim --headless --clean -u NONE -l scripts/check-integration.lua
nvim --headless --clean -u NONE -l scripts/check-notify.lua
nvim --headless --clean -u NONE -l scripts/check-dap-registry.lua
nvim --headless --clean -u NONE -l scripts/check-dap-executables.lua
```

Python 3 is required by `scripts/check.sh`; it is a development/checking dependency, not a Neovim runtime dependency. Set `REQUIRE_LUA=1`, `REQUIRE_NVIM=1`, and `REQUIRE_STYLUA=1` when the corresponding tools must be present.

## Plugin changes

- Update the plugin specification and `lazy-lock.json` together.
- Update [plugin-inventory.md](plugin-inventory.md).
- Declare runtime dependencies in the plugin specification rather than relying on incidental load order.
- Do not add Mason; language servers, compilers, and LLDB are installed outside Neovim.
- Test plugin behavior after synchronization. Headless smoke tests that import a plugin specification do not prove the plugin itself works.

## Platform and UI changes

- Avoid hard-coded machine-specific paths outside the path resolver.
- Preserve Windows, WSL, Linux, macOS, and Termux behavior where the feature applies.
- For process execution, use the shared process helper so timeouts terminate and reap child processes.
- For custom windows, use the shared UI helpers and preserve close/cleanup behavior.
- Keep GUI-only behavior documented as requiring manual Neovide verification.

## Pull requests and review

- Keep each change focused and explain the behavior it changes.
- Include tests for behavior, not just source-text patterns, when practical.
- State which checks were run and which platform-specific workflows remain untested.
- Do not claim a real LLDB, terminal, clipboard, Neovide, or third-party plugin integration passed based only on headless CI.
