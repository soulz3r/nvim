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
    -c "lua require('soul.launch')" \
    -c "lua assert(require('soul.core.platform').name)" \
    -c "lua require('soul.core.helpers.paths')" \
    -c "lua require('soul.core.options')" \
    -c "lua require('soul.core.keymaps')" \
    -c "lua require('soul.core.autocmds')" \
    -c "lua require('soul.core.helpers.ui')" \
    -c "lua require('soul.core.helpers.ui.output')" \
    -c "lua require('soul.core.neovide')" \
    -c "lua local modules = { 'soul.plugins.alpha', 'soul.plugins.breadcrumbs', 'soul.plugins.devicons', 'soul.plugins.gitsigns', 'soul.plugins.lualine', 'soul.plugins.mini', 'soul.plugins.render_md', 'soul.plugins.telescope', 'soul.plugins.yap', 'soul.plugins.toggleterm', 'soul.plugins.treesitter', 'soul.plugins.whichkey', 'soul.lsp.lsp', 'soul.lsp.dap', 'soul.cmp.blink', 'soul.extras.colorizer', 'soul.extras.everforest', 'soul.extras.eyeliner', 'soul.extras.tiny_cmdline', 'soul.extras.todo', 'soul.extras.ufo' }; for _, name in ipairs(modules) do local ok, spec = pcall(require, name); assert(ok, name .. ': ' .. tostring(spec)); assert(type(spec) == 'table', name .. ' did not return a spec table'); end" \
    -c "qa!"
  echo "Neovim module smoke tests passed."
fi

echo "JSON, repository hygiene, and available runtime checks passed."
