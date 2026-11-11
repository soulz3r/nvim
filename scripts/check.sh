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

if [[ -e lsp/dap-projects.json ]]; then
  echo "lsp/dap-projects.json is local DAP state and must not be committed." >&2
  exit 1
fi

# Autocmd file patterns do not support a leading "!" as a negative match.
if grep -nF 'pattern = { "!vim" }' lua/soul/core/autocmds.lua; then
  echo "Invalid negative autocmd pattern detected." >&2
  exit 1
fi

if grep -RInE --include='*.lua' '^[[:space:]]*function[[:space:]]+OPTS[[:space:]]*\(' lua; then
  echo "OPTS must remain a local/shared helper, not a global function." >&2
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
