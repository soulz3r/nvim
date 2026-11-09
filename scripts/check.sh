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

if grep -RIn --include='*.lua' -E 'vim\.loop|cmp_nvim_lsp|Telescope projects|open_mini_files' init.lua lua lsp; then
  echo "Found a stale API or broken plugin reference." >&2
  exit 1
fi

echo "JSON, local-state, and stale-reference checks passed."
