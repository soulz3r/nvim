#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Missing python3. Install Python 3 to validate JSON files." >&2
  exit 1
fi

python3 -m json.tool lazy-lock.json >/dev/null
python3 -m json.tool .luarc.json >/dev/null

if [[ -e lsp/dap-projects.json ]]; then
  echo "lsp/dap-projects.json is local DAP state and must not be committed." >&2
  exit 1
fi

# Private Neovim APIs are not allowed in the core configuration. UI2 is the
# sole exception and must remain isolated in the optional tiny-cmdline module.
if grep -RInE --include='*.lua' --exclude='tiny_cmdline.lua' 'vim\._' lua; then
  echo "Private Neovim APIs must stay out of the core configuration." >&2
  exit 1
fi

if ! grep -q 'vim\._core\.ui2' lua/soul/extras/tiny_cmdline.lua; then
  echo "The UI2 compatibility exception moved; review scripts/check.sh." >&2
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
  if grep -RInE --include='*.lua' "$pattern" lua; then
    echo "Legacy or deprecated API detected: $pattern" >&2
    exit 1
  fi
done

if command -v luac >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    luac -p "$file"
  done < <(find . -type f -name '*.lua' -not -path './.git/*' -print0)
  echo "Lua syntax checks passed."
elif [[ "${REQUIRE_LUA:-0}" == "1" ]]; then
  echo "Missing luac; Lua syntax checks are required in this environment." >&2
  exit 1
else
  echo "Skipping Lua syntax checks (luac is not installed)."
fi

if command -v nvim >/dev/null 2>&1; then
  nvim --headless --clean -u NONE \
    -c "luafile scripts/check-nvim.lua" \
    -c "qa!"
  echo "Neovim module smoke tests passed."
elif [[ "${REQUIRE_NVIM:-0}" == "1" ]]; then
  echo "Missing Neovim; runtime checks are required in this environment." >&2
  exit 1
else
  echo "Skipping Neovim smoke tests (nvim is not installed)."
fi

echo "Repository compatibility checks passed."
