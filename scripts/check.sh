#!/usr/bin/env bash
set -euo pipefail

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


if command -v luac >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do
    luac -p "$file"
  done < <(find . -type f -name '*.lua' -not -path './.git/*' -print0)
  echo "Lua syntax checks passed."
fi

if command -v nvim >/dev/null 2>&1; then
  nvim --headless --clean -u NONE \
    --cmd "set rtp+=." \
    --cmd "lua package.path = './lua/?.lua;./lua/?/init.lua;' .. package.path" \
    -c "lua assert(require('soul.core.project_registry'))" \
    -c "lua assert(require('soul.ui'))" \
    -c "lua assert(require('soul.c'))" \
    -c "qa!"
  echo "Neovim module smoke tests passed."
fi

echo "JSON, local-state, stale-reference, and available runtime checks passed."
