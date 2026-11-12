#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PYTHON="$(command -v python3 || command -v python || true)"
if [[ -z "$PYTHON" ]]; then
  echo "Missing Python 3. Install Python 3 to validate JSON files." >&2
  exit 1
fi

"$PYTHON" -m json.tool lazy-lock.json >/dev/null
"$PYTHON" -m json.tool .luarc.json >/dev/null

"$PYTHON" - <<'PY'
import json
import re
import sys

with open("lazy-lock.json", encoding="utf-8") as lock_file:
    lock = json.load(lock_file)

if not isinstance(lock, dict) or not lock:
    sys.exit("lazy-lock.json must contain a non-empty plugin map")

luarc = json.load(open(".luarc.json", encoding="utf-8"))
if "param-type-mismatch" in luarc.get("diagnostics.disable", []):
    sys.exit("LuaLS parameter type diagnostics must not be disabled globally")

for plugin, metadata in lock.items():
    if not isinstance(metadata, dict):
        sys.exit(f"Invalid lock entry for {plugin}")
    if not isinstance(metadata.get("branch"), str) or not metadata["branch"]:
        sys.exit(f"Missing branch for locked plugin {plugin}")
    commit = metadata.get("commit", "")
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        sys.exit(f"Invalid commit SHA for locked plugin {plugin}")

print(f"Validated {len(lock)} locked plugin revisions.")
PY

# Test the indentation checker itself, then enforce the repository-wide policy.
"$PYTHON" -m unittest discover -s scripts -p 'test_*.py'
"$PYTHON" scripts/lua_indentation.py

if [[ -e lsp/dap-projects.json ]]; then
  echo "lsp/dap-projects.json is local DAP state and must not be committed." >&2
  exit 1
fi

# Autocmd file patterns do not support a leading "!" as a negative match.
if grep -nF 'tabdo wincmd =' lua/soul/core/autocmds.lua; then
  echo "Window resizing must not overwrite manually adjusted split sizes." >&2
  exit 1
fi

if grep -nF 'pattern = { "!vim" }' lua/soul/core/autocmds.lua; then
  echo "Invalid negative autocmd pattern detected." >&2
  exit 1
fi

if grep -RInE --include='*.lua' '^[[:space:]]*function[[:space:]]+OPTS[[:space:]]*[(]' lua; then
  echo "OPTS must remain a local/shared helper, not a global function." >&2
  exit 1
fi

if grep -q '"OPTS"' lsp/lua_ls.lua; then
  echo "LuaLS must not declare OPTS as a global." >&2
  exit 1
fi

if ! grep -q '"help"' lua/soul/plugins/treesitter.lua; then
  echo "Treesitter must start for help buffers using the vimdoc parser." >&2
  exit 1
fi

if grep -q 'disabled_buftypes = { "alpha" }' lua/soul/extras/eyeliner.lua; then
  echo "Alpha is a filetype, not a buftype; remove the invalid Eyeliner filter." >&2
  exit 1
fi

if grep -q 'lua/soul/plugins/mini/init.lua' docs/architecture.md; then
  echo "Architecture docs contain the obsolete Mini plugin path." >&2
  exit 1
fi

if ! grep -q 'GET("soul.plugins.undotree")' init.lua; then
  echo "Undotree plugin specification must be registered from init.lua." >&2
  exit 1
fi

if grep -q 'nvim.undotree' lua/soul/core/keymaps.lua; then
  echo "The old undeclared Undotree package command must not return." >&2
  exit 1
fi

if [[ -e lua/soul/plugins/oil.lua ]]; then
  echo "The unused Oil specification conflicts with the Mini Files choice." >&2
  exit 1
fi

if ! grep -q 'dependencies = { "nvim-mini/mini.icons" }' lua/soul/plugins/mini.lua; then
  echo "Mini Files must declare Mini Icons as a dependency." >&2
  exit 1
fi

if ! grep -q 'telescope = true' lua/soul/plugins/yap.lua; then
  echo "YAP's Telescope project integration must be enabled for its project keymaps." >&2
  exit 1
fi

if grep -Eq 'nui-components|nui\.nvim' lua/soul/plugins/yap.lua; then
  echo "YAP no longer uses Nui dependencies; remove stale UI dependencies." >&2
  exit 1
fi

if grep -q 'synchronize_without_confirmation\|vim\.fn\.confirm[[:space:]]*=' lua/soul/core/helpers/mini/files.lua; then
  echo "Mini Files synchronization must retain its normal destructive-operation confirmation." >&2
  exit 1
fi

if ! grep -q 'install_task:await' lua/soul/plugins/treesitter.lua; then
  echo "Treesitter must retry buffers after asynchronous parser installation." >&2
  exit 1
fi

if ! grep -q 'build = function(plugin)' lua/soul/plugins/telescope.lua; then
  echo "Telescope fzf-native must use the platform-aware native build function." >&2
  exit 1
fi

if grep -q '"<leader>pq"\|"<leader>pi"' lua/soul/plugins/whichkey.lua; then
  echo "WhichKey must not advertise YAP mappings that do not exist." >&2
  exit 1
fi

# Private Neovim APIs are not allowed in the core configuration. UI2 is the
# sole exception and must remain isolated in the optional tiny-cmdline module.
if grep -RInE --include='*.lua' --exclude='tiny_cmdline.lua' --exclude-dir='.git' 'vim\._' .; then
  echo "Private Neovim APIs must stay out of the core configuration." >&2
  exit 1
fi

if ! grep -q 'vim\._core\.ui2' lua/soul/extras/tiny_cmdline.lua; then
  echo "The UI2 compatibility exception moved; review scripts/check.sh." >&2
  exit 1
fi

ui2_private_refs="$(grep -o 'vim\._' lua/soul/extras/tiny_cmdline.lua | wc -l | tr -d ' ')"
if [[ "$ui2_private_refs" != "1" ]]; then
  echo "Only the single UI2 module import is allowed in tiny_cmdline.lua." >&2
  exit 1
fi

legacy_patterns=(
  'vim\.loop'
  'vim\.lsp\.get_active_clients'
  'vim\.lsp\.buf_get_clients'
  'nvim_buf_(get|set)_option\('
  'nvim_win_(get|set)_option\('
  'nvim_(get|set)_option\('
  'nvim_set_keymap\('
  'require\(["'\'' ]lspconfig["'\'' ]\)'
  'require\(["'\'' ]nvim-treesitter\.configs["'\'' ]\)'
)

for pattern in "${legacy_patterns[@]}"; do
  if grep -RInE --include='*.lua' --exclude-dir='.git' "$pattern" .; then
    echo "Legacy or deprecated API detected: $pattern" >&2
    exit 1
  fi
done

LUAC="$(command -v luac || command -v luac.exe || true)"
if [[ -n "$LUAC" ]]; then
  while IFS= read -r -d '' file; do
    "$LUAC" -p "$file"
  done < <(find . -type f -name '*.lua' -not -path './.git/*' -print0)
  echo "Lua syntax checks passed."
elif [[ "${REQUIRE_LUA:-0}" == "1" ]]; then
  echo "Missing luac or luac.exe; Lua syntax checks are required in this environment." >&2
  exit 1
else
  echo "Skipping Lua syntax checks (luac is not installed)."
fi

STYLUA="$(command -v stylua || command -v stylua.exe || true)"
if [[ -n "$STYLUA" ]]; then
  stylua_output="$(mktemp)"
  if "$STYLUA" --check . >"$stylua_output" 2>&1; then
    echo "StyLua formatting checks passed."
  else
    echo "StyLua formatting checks failed:"
    if grep -q '^Diff in ' "$stylua_output"; then
      grep '^Diff in ' "$stylua_output" | sed 's/^Diff in //; s/:$//' | sort -u | sed 's/^/  /'
      echo "Run 'stylua .' to apply formatting after resolving the line-ending policy."
    else
      cat "$stylua_output"
    fi
    rm -f "$stylua_output"
    exit 1
  fi
  rm -f "$stylua_output"
elif [[ "${REQUIRE_STYLUA:-0}" == "1" ]]; then
  echo "Missing StyLua; formatting checks are required in this environment." >&2
  exit 1
else
  echo "Skipping StyLua checks (stylua is not installed)."
fi

if command -v nvim >/dev/null 2>&1; then
  nvim --headless --clean -u NONE -l scripts/check-nvim.lua
  echo "Neovim module smoke tests passed."
  nvim --headless --clean -u NONE -l scripts/check-integration.lua
  nvim --headless --clean -u NONE -l scripts/check-notify.lua
  nvim --headless --clean -u NONE -l scripts/check-dap-registry.lua
  nvim --headless --clean -u NONE -l scripts/check-dap-executables.lua
elif [[ "${REQUIRE_NVIM:-0}" == "1" ]]; then
  echo "Missing Neovim; runtime checks are required in this environment." >&2
  exit 1
else
  echo "Skipping Neovim smoke tests (nvim is not installed)."
fi

echo "Repository compatibility checks passed."
