#!/usr/bin/env bash
set -uo pipefail

# Bash's high-resolution clock measures the entire check script.
timestamp_us() {
  local timestamp="$EPOCHREALTIME"
  local seconds="${timestamp%.*}"
  local fraction="${timestamp#*.}"
  printf '%s' "$(( 10#$seconds * 1000000 + 10#${fraction:0:6} ))"
}

START_TIME_US="$(timestamp_us)"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Keep the output readable in narrow terminals and plain logs.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  GREEN=$'\033[32m'
  RED=$'\033[31m'
  CYAN=$'\033[36m'
  YELLOW=$'\033[33m'
else
  RESET=''
  BOLD=''
  DIM=''
  GREEN=''
  RED=''
  CYAN=''
  YELLOW=''
fi

TERM_WIDTH="$(tput cols 2>/dev/null || printf '80')"
[[ "$TERM_WIDTH" =~ ^[0-9]+$ ]] || TERM_WIDTH=80
(( TERM_WIDTH < 60 )) && TERM_WIDTH=60
(( TERM_WIDTH > 120 )) && TERM_WIDTH=120

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

CHECK_COUNT=0
FAIL_COUNT=0
UNIT_SUMMARY=''
UNIT_RESULT=''

repeat_char() {
  local char="$1"
  local count="$2"
  printf -v REPEATED '%*s' "$count" ''
  printf '%s' "${REPEATED// /$char}"
}

center_line() {
  local value="$1"
  local padding=$(( (TERM_WIDTH - ${#value}) / 2 ))
  (( padding < 0 )) && padding=0
  printf '%*s%s\n' "$padding" '' "$value"
}

print_header() {
  local branch commit title
  branch="$(git branch --show-current 2>/dev/null || printf 'unknown branch')"
  commit="$(git rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  title="REPOSITORY CHECKS"

  printf '\n%s%s' "$CYAN" "$BOLD"
  repeat_char '─' "$TERM_WIDTH"
  printf '\n'
  center_line "$title"
  center_line "$branch  •  $commit"
  repeat_char '─' "$TERM_WIDTH"
  printf '\n%s\n' "$RESET"
}

print_status() {
  local label="$1"
  local state="$2"
  local color="$GREEN"
  local status_width=6
  local label_width=$(( TERM_WIDTH - 13 ))

  (( CHECK_COUNT += 1 ))
  (( label_width < 20 )) && label_width=20

  [[ "$state" == "FAIL" ]] && color="$RED"
  [[ "$state" == "SKIP" ]] && color="$YELLOW"

  printf '  %s%02d%s  %-*.*s %s%*s%s\n' \
    "$DIM" "$CHECK_COUNT" "$RESET" \
    "$label_width" "$label_width" "$label" \
    "$color" "$status_width" "$state" "$RESET"
}

run_check() {
  local label="$1"
  local show_output="${2:-0}"
  shift 2
  local output="$TEMP_DIR/check-$((CHECK_COUNT + 1)).log"

  if "$@" >"$output" 2>&1; then
    print_status "$label" "PASS"
    if [[ "$show_output" == "1" && -s "$output" ]]; then
      while IFS= read -r line; do
        [[ "$line" == *" passed." || "$line" == "OK" ]] && continue
        printf '      %s%s%s\n' "$DIM" "$line" "$RESET"
      done <"$output"
    fi
    return 0
  fi

  print_status "$label" "FAIL"
  sed 's/^/      /' "$output"
  (( FAIL_COUNT += 1 ))
  return 0
}

run_shell_check() {
  local label="$1"
  shift
  local output="$TEMP_DIR/check-$((CHECK_COUNT + 1)).log"

  if "$@" >"$output" 2>&1; then
    print_status "$label" "PASS"
  else
    print_status "$label" "FAIL"
    sed 's/^/      /' "$output"
    (( FAIL_COUNT += 1 ))
  fi
}

PYTHON="$(command -v python3 || command -v python || true)"
if [[ -z "$PYTHON" ]]; then
  printf '%sMissing Python 3. Install Python 3 to validate JSON files.%s\n' "$RED" "$RESET" >&2
  exit 1
fi

print_header

run_check "Plugin lockfile and LuaLS configuration" 1 "$PYTHON" - <<'PY'
import json
import re
import sys

with open("lazy-lock.json", encoding="utf-8") as lock_file:
    lock = json.load(lock_file)

if not isinstance(lock, dict) or not lock:
    sys.exit("lazy-lock.json must contain a non-empty plugin map")

with open(".luarc.json", encoding="utf-8") as config_file:
    luarc = json.load(config_file)

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

# Keep the unittest report until the end so its summary reflects completed work.
UNIT_OUTPUT="$TEMP_DIR/unittest.log"
if "$PYTHON" -m unittest discover -s scripts -p 'test_*.py' >"$UNIT_OUTPUT" 2>&1; then
  print_status "Python unit tests" "PASS"
  UNIT_SUMMARY="$(grep -E '^Ran [0-9]+ tests? in ' "$UNIT_OUTPUT" | tail -n 1 | sed -E 's/ in [0-9.]+s$//' || true)"
  UNIT_RESULT="$(grep -E '^(OK|FAILED)( \(.*\))?$' "$UNIT_OUTPUT" | tail -n 1 || true)"
else
  print_status "Python unit tests" "FAIL"
  sed 's/^/      /' "$UNIT_OUTPUT"
  UNIT_SUMMARY="$(grep -E '^Ran [0-9]+ tests? in ' "$UNIT_OUTPUT" | tail -n 1 | sed -E 's/ in [0-9.]+s$//' || true)"
  UNIT_RESULT="$(grep -E '^(OK|FAILED)( \(.*\))?$' "$UNIT_OUTPUT" | tail -n 1 || true)"
  (( FAIL_COUNT += 1 ))
fi

run_check "Lua indentation and line endings" 0 "$PYTHON" scripts/lua_indentation.py

compatibility_checks() {
  [[ ! -e lsp/dap-projects.json ]] || {
    echo "lsp/dap-projects.json is local DAP state and must not be committed."
    return 1
  }

  if grep -nF 'tabdo wincmd =' lua/soul/core/autocmds.lua; then
    echo "Window resizing must not overwrite manually adjusted split sizes."
    return 1
  fi

  if grep -nF 'pattern = { "!vim" }' lua/soul/core/autocmds.lua; then
    echo "Invalid negative autocmd pattern detected."
    return 1
  fi

  if grep -RInE --include='*.lua' '^[[:space:]]*function[[:space:]]+OPTS[[:space:]]*[(]' lua; then
    echo "OPTS must remain a local/shared helper, not a global function."
    return 1
  fi

  if grep -q '"OPTS"' lsp/lua_ls.lua; then
    echo "LuaLS must not declare OPTS as a global."
    return 1
  fi

  if ! grep -q '"help"' lua/soul/plugins/treesitter.lua; then
    echo "Treesitter must start for help buffers using the vimdoc parser."
    return 1
  fi

  if grep -q 'disabled_buftypes = { "alpha" }' lua/soul/extras/eyeliner.lua; then
    echo "Alpha is a filetype, not a buftype; remove the invalid Eyeliner filter."
    return 1
  fi

  if grep -q 'lua/soul/plugins/mini/init.lua' docs/architecture.md; then
    echo "Architecture docs contain the obsolete Mini plugin path."
    return 1
  fi

  if ! grep -q 'GET("soul.plugins.undotree")' init.lua; then
    echo "Undotree plugin specification must be registered from init.lua."
    return 1
  fi

  if grep -q 'nvim.undotree' lua/soul/core/keymaps.lua; then
    echo "The old undeclared Undotree package command must not return."
    return 1
  fi

  if [[ -e lua/soul/plugins/oil.lua ]]; then
    echo "The unused Oil specification conflicts with the Mini Files choice."
    return 1
  fi

  if ! grep -q 'dependencies = { "nvim-mini/mini.icons" }' lua/soul/plugins/mini.lua; then
    echo "Mini Files must declare Mini Icons as a dependency."
    return 1
  fi

  if ! grep -q 'telescope = true' lua/soul/plugins/yap.lua; then
    echo "YAP's Telescope project integration must be enabled for its project keymaps."
    return 1
  fi

  if grep -nF 'soulz3r/yap.nvim' lua/soul/lsp/dap.lua lua/soul/core/helpers/dap \
    || grep -nF 'require("yap' lua/soul/lsp/dap.lua lua/soul/core/helpers/dap \
    || grep -nF "require('yap" lua/soul/lsp/dap.lua lua/soul/core/helpers/dap; then
    echo "DAP must not depend on YAP's plugin or Lua modules."
    return 1
  fi

  if grep -q 'dependencies = { "soulz3r/yap.nvim" }' lua/soul/plugins/lualine.lua; then
    echo "Lualine's YAP project label must remain optional."
    return 1
  fi

  if ! grep -q 'pcall(require, "yap.project_registry")' lua/soul/plugins/lualine.lua; then
    echo "Lualine must guard its optional YAP project-status integration."
    return 1
  fi

  if grep -Eq 'nui-components|nui\.nvim' lua/soul/plugins/yap.lua; then
    echo "YAP no longer uses Nui dependencies; remove stale UI dependencies."
    return 1
  fi

  if grep -q 'synchronize_without_confirmation\|vim\.fn\.confirm[[:space:]]*=' lua/soul/core/helpers/mini/files.lua; then
    echo "Mini Files synchronization must retain its normal destructive-operation confirmation."
    return 1
  fi

  if ! grep -q 'install_task:await' lua/soul/plugins/treesitter.lua; then
    echo "Treesitter must retry buffers after asynchronous parser installation."
    return 1
  fi

  if ! grep -q 'build = require("soul.core.helpers.fzf_native").build' lua/soul/plugins/telescope.lua; then
    echo "Telescope fzf-native must use the extracted platform-aware build helper."
    return 1
  fi

  if grep -q '"<leader>pq"\|"<leader>pi"' lua/soul/plugins/whichkey.lua; then
    echo "WhichKey must not advertise YAP mappings that do not exist."
    return 1
  fi

  # Private Neovim APIs are not allowed in core. UI2 is isolated in tiny-cmdline.
  if grep -RInE --include='*.lua' --exclude='tiny_cmdline.lua' --exclude-dir='.git' 'vim\._' .; then
    echo "Private Neovim APIs must stay out of the core configuration."
    return 1
  fi

  if ! grep -q 'vim\._core\.ui2' lua/soul/extras/tiny_cmdline.lua; then
    echo "The UI2 compatibility exception moved; review scripts/check.sh."
    return 1
  fi

  local ui2_private_refs
  ui2_private_refs="$(grep -o 'vim\._' lua/soul/extras/tiny_cmdline.lua | wc -l | tr -d ' ')"
  if [[ "$ui2_private_refs" != "1" ]]; then
    echo "Only the single UI2 module import is allowed in tiny_cmdline.lua."
    return 1
  fi

  local legacy_patterns=(
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

  local pattern
  for pattern in "${legacy_patterns[@]}"; do
    if grep -RInE --include='*.lua' --exclude-dir='.git' "$pattern" .; then
      echo "Legacy or deprecated API detected: $pattern"
      return 1
    fi
  done
}

run_shell_check "Repository compatibility rules" compatibility_checks

LUAC="$(command -v luac || command -v luac.exe || true)"
if [[ -n "$LUAC" ]]; then
  run_check "Lua syntax" 0 bash -c '
    set -e
    while IFS= read -r -d "" file; do
      "$1" -p "$file"
    done < <(find . -type f -name "*.lua" -not -path "./.git/*" -print0)
  ' _ "$LUAC"
elif [[ "${REQUIRE_LUA:-0}" == "1" ]]; then
  print_status "Lua syntax (luac missing)" "FAIL"
  (( FAIL_COUNT += 1 ))
else
  print_status "Lua syntax (luac not installed)" "SKIP"
fi

STYLUA="$(command -v stylua || command -v stylua.exe || true)"
if [[ -n "$STYLUA" ]]; then
  STYLUA_OUTPUT="$TEMP_DIR/stylua.log"
  if "$STYLUA" --check . >"$STYLUA_OUTPUT" 2>&1; then
    print_status "StyLua formatting" "PASS"
  else
    print_status "StyLua formatting" "FAIL"
    if grep -q '^Diff in ' "$STYLUA_OUTPUT"; then
      grep '^Diff in ' "$STYLUA_OUTPUT" | sed 's/^Diff in //; s/:$//' | sort -u | sed 's/^/      /'
      printf '      %sRun stylua . after resolving the line-ending policy.%s\n' "$DIM" "$RESET"
    else
      sed 's/^/      /' "$STYLUA_OUTPUT"
    fi
    (( FAIL_COUNT += 1 ))
  fi
elif [[ "${REQUIRE_STYLUA:-0}" == "1" ]]; then
  print_status "StyLua (not installed)" "FAIL"
  (( FAIL_COUNT += 1 ))
else
  print_status "StyLua (not installed)" "SKIP"
fi

if command -v nvim >/dev/null 2>&1; then
  run_check "Neovim core and plugin-spec smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-nvim.lua
  run_check "Neovim module smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-integration.lua
  run_check "Mini Notify progress lifecycle" 0 nvim --headless --clean -u NONE -l scripts/check-notify.lua
  run_check "DAP registry migration" 0 nvim --headless --clean -u NONE -l scripts/check-dap-registry.lua
  run_check "DAP executable discovery" 0 nvim --headless --clean -u NONE -l scripts/check-dap-executables.lua
  run_check "DAP path and project resolution" 1 nvim --headless --clean -u NONE -l scripts/check-dap-project.lua
elif [[ "${REQUIRE_NVIM:-0}" == "1" ]]; then
  print_status "Neovim runtime checks (not installed)" "FAIL"
  (( FAIL_COUNT += 1 ))
else
  print_status "Neovim runtime checks (not installed)" "SKIP"
fi

printf '\n'
repeat_char '─' "$TERM_WIDTH"
printf '\n'

# The unittest summary is intentionally displayed last, after every check ran.
if [[ -n "$UNIT_SUMMARY" ]]; then
  center_line "$UNIT_SUMMARY"
fi
if [[ -n "$UNIT_RESULT" ]]; then
  if [[ "$UNIT_RESULT" == "OK" ]]; then
    printf '%s' "$GREEN"
  else
    printf '%s' "$RED"
  fi
  center_line "$UNIT_RESULT"
  printf '%s' "$RESET"
fi

END_TIME_US="$(timestamp_us)"
ELAPSED_US=$(( END_TIME_US - START_TIME_US ))
ELAPSED_SECONDS=$(( ELAPSED_US / 1000000 ))
ELAPSED_MILLISECONDS=$(( (ELAPSED_US % 1000000) / 1000 ))
printf '\n'
center_line "TOTAL CHECK TIME  ${ELAPSED_SECONDS}.$(printf '%03d' "$ELAPSED_MILLISECONDS")s"

if (( FAIL_COUNT == 0 )); then
  printf '\n%s' "$GREEN"
  center_line "ALL CHECKS PASSED  ✓"
  printf '%s' "$RESET"
else
  printf '\n%s' "$RED"
  center_line "$FAIL_COUNT CHECK(S) FAILED"
  printf '%s' "$RESET"
fi

exit "$(( FAIL_COUNT > 0 ))"
