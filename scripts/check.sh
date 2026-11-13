#!/usr/bin/env bash
set -uo pipefail

# Bash's high-resolution clock measures the entire check script.
timestamp_us() {
  local timestamp="${EPOCHREALTIME:-}"

  if [[ -n "$timestamp" ]]; then
    local seconds="${timestamp%.*}"
    local fraction="${timestamp#*.}"
    printf '%s' "$(( 10#$seconds * 1000000 + 10#${fraction:0:6} ))"
  else
    local python
    python="$(command -v python3 || command -v python)"
    "$python" -c 'import time; print(time.time_ns() // 1000)'
  fi
}

START_TIME_US="$(timestamp_us)"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Git Bash uses POSIX paths while native Windows Neovim expects drive paths.
# Convert only values crossing the process environment boundary.
to_native_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s' "$1"
  fi
}

to_shell_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  else
    printf '%s' "$1"
  fi
}

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

  if grep -q 'GET("soul.plugins")\|GET("soul.extras")' init.lua; then
    echo "Plugin specs must be loaded directly instead of through Lazy directory imports."
    return 1
  fi

  if ! grep -q 'GET("soul.plugins.undotree")' init.lua; then
    echo "Undotree plugin specification must be registered directly with Lazy."
    return 1
  fi

  if ! grep -q 'table.insert(LAZY_PLUGIN_GET, require(module))' lua/soul/launch.lua; then
    echo "GET must register the returned plugin spec table, not a Lazy import path."
    return 1
  fi

  if [[ ! -f lua/soul/plugins/undotree.lua ]]; then
    echo "Undotree plugin specification is missing."
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

  if grep -RInF 'soulz3r/yap.nvim' lua/soul/lsp/dap.lua lua/soul/core/helpers/dap \
    || grep -RInF 'require("yap' lua/soul/lsp/dap.lua lua/soul/core/helpers/dap \
    || grep -RInF "require('yap" lua/soul/lsp/dap.lua lua/soul/core/helpers/dap; then
    echo "DAP must not depend on YAP's plugin or Lua modules."
    return 1
  fi

  if grep -q 'dependencies = { "soulz3r/yap.nvim" }' lua/soul/plugins/lualine.lua; then
    echo "Lualine's YAP project label must remain optional."
    return 1
  fi

  if ! grep -q 'package.loaded\["yap.project_registry"\]' lua/soul/plugins/lualine.lua; then
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

  if grep -q 'M.pwsh = find_powershell()' lua/soul/core/helpers/paths.lua; then
    echo "PowerShell discovery must not run while core paths are imported."
    return 1
  fi

  if ! grep -q 'function M.resolve_powershell()' lua/soul/core/helpers/paths.lua \
    || ! grep -q 'require("soul.core.helpers.powershell").resolve()' lua/soul/core/helpers/paths.lua; then
    echo "PowerShell discovery must remain behind its lazy resolver module."
    return 1
  fi

  if grep -q 'find_powershell' lua/soul/core/helpers/paths.lua; then
    echo "PowerShell discovery implementation must stay out of core paths."
    return 1
  fi

  if ! grep -q 'vim.g.cvim_config_loaded = true' init.lua \
    || ! grep -q 'vim.g.cvim_alpha_ready = true' lua/soul/plugins/alpha.lua \
    || ! grep -q 'vim.g.cvim_keymaps_ready = true' init.lua \
    || ! grep -q 'vim.g.cvim_config_loaded ~= true or vim.g.cvim_alpha_ready ~= true or vim.g.cvim_keymaps_ready ~= true' scripts/check.sh; then
    echo "The configured startup benchmark must verify that this checkout loaded."
    return 1
  fi

  if ! grep -q 'CVIM_PROFILE_OUTPUT' scripts/profile-init.lua; then
    echo "The optional module profiler must write a machine-readable report."
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

benchmark_startup() {
  local runs="${CVIM_STARTUP_RUNS:-5}"
  local benchmark_dir="$TEMP_DIR/startup-benchmark"
  local mode log output elapsed ready_output ready_elapsed
  local failed=0
  local run

  if [[ ! "$runs" =~ ^[1-9][0-9]*$ ]]; then
    print_status "Startup performance benchmark (invalid run count)" "FAIL"
    printf '      CVIM_STARTUP_RUNS must be a positive integer; received: %s\n' "$runs"
    (( FAIL_COUNT += 1 ))
    return
  fi

  mkdir -p "$benchmark_dir"
  : >"$benchmark_dir/configured-ready.times"

  # The configured sample must load this checkout, not whatever happens to be
  # installed as the user's default config. CI runners without Lazy installed
  # cannot boot the full config, so report that limitation instead of silently
  # benchmarking a clean Neovim process.
  local data_dir lazy_entry alpha_entry
  data_dir="$(nvim --headless --clean -u NONE -c 'lua io.write(vim.fn.stdpath("data"))' -c 'qa!' 2>/dev/null)"
  data_dir="$(to_shell_path "$data_dir")"
  lazy_entry="$data_dir/lazy/lazy.nvim/lua/lazy/init.lua"
  alpha_entry="$data_dir/lazy/alpha-nvim/lua/alpha.lua"

  local config_path
  config_path="$ROOT"

  if [[ ! -f "$lazy_entry" ]]; then
    print_status "CVIM startup benchmark (Lazy unavailable)" "SKIP"
    printf '      Install the CVIM plugin dependencies to benchmark the configured checkout.\n'
    return
  fi

  if [[ ! -f "$alpha_entry" ]]; then
    print_status "CVIM startup benchmark (Alpha unavailable)" "SKIP"
    printf '      Install alpha-nvim to benchmark the first usable dashboard screen.\n'
    return
  fi

  for mode in configured clean; do
    : >"$benchmark_dir/$mode.times"

    for (( run = 1; run <= runs; run++ )); do
      log="$benchmark_dir/$mode-$run.log"
      output="$benchmark_dir/$mode-$run.output"

      if [[ "$mode" == "clean" ]]; then
        if ! nvim --clean --headless --startuptime "$log" -c 'qa!' >"$output" 2>&1; then
          failed=1
          break
        fi
      else
        ready_output="$benchmark_dir/configured-ready-$run.ms"
        local ready_output_native
        ready_output_native="$(to_native_path "$ready_output")"

        if ! CVIM_BENCHMARK=1 CVIM_CONFIG="$config_path" CVIM_BENCHMARK_READY_OUTPUT="$ready_output_native" nvim --headless --startuptime "$log" \
          -u "$ROOT/init.lua" \
          --cmd 'lua vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function() vim.schedule(function() local ready = vim.wait(5000, function() return vim.g.cvim_config_loaded == true and vim.g.cvim_alpha_ready == true and vim.g.cvim_keymaps_ready == true end, 10); if not ready then io.stderr:write(("CVIM startup readiness timeout: config_loaded=%s, alpha_ready=%s, keymaps_ready=%s, filetype=%s\\n"):format(tostring(vim.g.cvim_config_loaded), tostring(vim.g.cvim_alpha_ready), tostring(vim.g.cvim_keymaps_ready), vim.bo.filetype)); vim.cmd.cquit(); return end; vim.fn.writefile({ tostring(vim.g.cvim_alpha_ready_ms or -1) }, vim.env.CVIM_BENCHMARK_READY_OUTPUT); vim.cmd("qa!") end) end })' >"$output" 2>&1; then
          failed=1
          break
        fi
      fi

      elapsed="$(awk '/--- NVIM STARTED ---/ { value = $1 } END { if (value != "") print value; else exit 1 }' "$log" 2>/dev/null || true)"
      if [[ ! "$elapsed" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        failed=1
        printf '      Could not read the NVIM STARTED timing from %s\n' "$log"
        sed 's/^/      /' "$output"
        break
      fi

      printf '%s\n' "$elapsed" >>"$benchmark_dir/$mode.times"
      if [[ "$mode" == "configured" ]]; then
        ready_elapsed="$(cat "$ready_output" 2>/dev/null || true)"
        if [[ ! "$ready_elapsed" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
          failed=1
          printf '      Could not read the Alpha-ready timing from %s\n' "$ready_output"
          sed 's/^/      /' "$output"
          break
        fi
        printf '%s\n' "$ready_elapsed" >>"$benchmark_dir/configured-ready.times"
      fi
    done

    if (( failed != 0 )); then
      break
    fi
  done

  if (( failed != 0 )); then
    print_status "Startup performance benchmark" "FAIL"
    printf '      Startup benchmark failed during the %s run.\n' "$mode"
    [[ ! -s "$output" ]] || sed 's/^/      /' "$output"
    (( FAIL_COUNT += 1 ))
    return
  fi

  print_status "Startup performance benchmark ($runs runs)" "PASS"
  "$PYTHON" - "$benchmark_dir" <<'PY'
import pathlib
import statistics
import sys

directory = pathlib.Path(sys.argv[1])

def read_samples(name):
    values = [float(line) for line in (directory / f"{name}.times").read_text().splitlines()]
    if not values:
        raise SystemExit(f"No startup measurements recorded for {name}")
    return values

configured = read_samples("configured")
clean = read_samples("clean")
alpha_ready = read_samples("configured-ready")
configured_median = statistics.median(configured)
clean_median = statistics.median(clean)
overhead = configured_median - clean_median
percent = (overhead / clean_median * 100) if clean_median else 0

print(f"      Configured CVIM: median {configured_median:.3f} ms "
      f"(min {min(configured):.3f}, max {max(configured):.3f})")
print(f"      Clean Neovim:    median {clean_median:.3f} ms "
      f"(min {min(clean):.3f}, max {max(clean):.3f})")
print(f"      Configuration overhead: {overhead:+.3f} ms ({percent:+.1f}%)")
print(f"      CVIM init to Alpha ready: median {statistics.median(alpha_ready):.3f} ms "
      f"(min {min(alpha_ready):.3f}, max {max(alpha_ready):.3f})")
print("      CVIM samples:  " + ", ".join(f"{value:.3f}" for value in configured))
print("      Clean samples: " + ", ".join(f"{value:.3f}" for value in clean))
PY
}

profile_startup() {
  [[ "${CVIM_STARTUP_PROFILE:-0}" == "1" ]] || return

  local data_dir lazy_entry alpha_entry profile_dir profile_output
  data_dir="$(nvim --headless --clean -u NONE -c 'lua io.write(vim.fn.stdpath("data"))' -c 'qa!' 2>/dev/null)"
  data_dir="$(to_shell_path "$data_dir")"
  lazy_entry="$data_dir/lazy/lazy.nvim/lua/lazy/init.lua"
  alpha_entry="$data_dir/lazy/alpha-nvim/lua/alpha.lua"

  if [[ ! -f "$lazy_entry" ]]; then
    print_status "CVIM module profile (Lazy unavailable)" "SKIP"
    return
  fi

  if [[ ! -f "$alpha_entry" ]]; then
    print_status "CVIM module profile (Alpha unavailable)" "SKIP"
    return
  fi

  profile_dir="$TEMP_DIR/startup-profile"
  profile_output="$profile_dir/modules.tsv"
  mkdir -p "$profile_dir"

  local config_path profile_output_path
  config_path="$ROOT"
  profile_output_path="$(to_native_path "$profile_output")"

  if ! CVIM_CONFIG="$config_path" CVIM_PROFILE_OUTPUT="$profile_output_path" nvim --headless \
    -u "$ROOT/scripts/profile-init.lua" >"$profile_dir/output.log" 2>&1; then
    print_status "CVIM module profile" "FAIL"
    sed 's/^/      /' "$profile_dir/output.log"
    (( FAIL_COUNT += 1 ))
    return
  fi

  if [[ ! -s "$profile_output" ]]; then
    print_status "CVIM module profile" "FAIL"
    printf '      The profiler did not produce its module report.\n'
    [[ ! -s "$profile_dir/output.log" ]] || sed 's/^/      /' "$profile_dir/output.log"
    (( FAIL_COUNT += 1 ))
    return
  fi

  if ! grep -Fq 'Alpha dashboard ready: true' "$profile_output"; then
    print_status "CVIM dashboard readiness (profile)" "FAIL"
    sed 's/^/      /' "$profile_output"
    (( FAIL_COUNT += 1 ))
    return
  fi

  print_status "CVIM module profile" "PASS"
  sed -n '1,100p' "$profile_output" | sed 's/^/      /'
}

if command -v nvim >/dev/null 2>&1; then
  run_check "Neovim core and plugin-spec smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-nvim.lua
  run_check "Neovim module smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-integration.lua
  run_check "Resource lifecycle and idle LSP cleanup" 0 nvim --headless --clean -u NONE -l scripts/check-lifecycle.lua
  run_check "Dashboard animation profiler" 0 nvim --headless --clean -u NONE -l scripts/check-animation-profile.lua
  run_check "Mini Notify progress lifecycle" 0 nvim --headless --clean -u NONE -l scripts/check-notify.lua
  run_check "DAP registry migration" 0 nvim --headless --clean -u NONE -l scripts/check-dap-registry.lua
  run_check "DAP executable discovery" 0 nvim --headless --clean -u NONE -l scripts/check-dap-executables.lua
  run_check "DAP path and project resolution" 1 nvim --headless --clean -u NONE -l scripts/check-dap-project.lua

  # A real file-backed startup must not load Alpha or any CVIM dashboard helper.
  printf 'return true\n' >"$TEMP_DIR/cvim-file-startup.lua"
  run_check "Dashboard skipped on file startup" 0 "$PYTHON" - "$ROOT" "$TEMP_DIR/cvim-file-startup.lua" <<'PY'
import subprocess
import sys

root, fixture = sys.argv[1:]
lua_check = (
    'local ok, err = pcall(function() '
    'local prefix = "soul.core.helpers.dashboard."; '
    'for name in pairs(package.loaded) do '
    'assert(name:sub(1, #prefix) ~= prefix, '
    '"dashboard module loaded during file startup: " .. name) '
    'end; '
    'assert(package.loaded["alpha"] == nil, "Alpha loaded during file startup"); '
    'assert(package.loaded["alpha.themes.dashboard"] == nil, '
    '"Alpha dashboard theme loaded during file startup") '
    'end); '
    'if not ok then io.stderr:write(tostring(err) .. "\\n"); vim.cmd("cquit") '
    'else vim.cmd("qa!") end'
)
command = (
    'export CVIM_CONFIG="$1"; '
    # Neovim command-line options must come before the file argument.
    'exec nvim --headless -u "$1/init.lua" -c "$3" "$2"'
)

try:
    result = subprocess.run(
        ["bash", "-c", command, "cvim-file-startup", root, fixture, lua_check],
        capture_output=True,
        text=True,
        timeout=20,
    )
except subprocess.TimeoutExpired:
    sys.exit("File-startup smoke test timed out after 20 seconds.")

if result.stdout:
    print(result.stdout, end="")
if result.stderr:
    print(result.stderr, end="", file=sys.stderr)
sys.exit(result.returncode)
PY

  benchmark_startup
  profile_startup
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
 "$profile_output"; then
    print_status "CVIM dashboard readiness (profile)" "FAIL"
    sed 's/^/      /' "$profile_output"
    (( FAIL_COUNT += 1 ))
    return
  fi

  print_status "CVIM module profile" "PASS"
  sed -n '1,100p' "$profile_output" | sed 's/^/      /'
}

if command -v nvim >/dev/null 2>&1; then
  run_check "Neovim core and plugin-spec smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-nvim.lua
  run_check "Neovim module smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-integration.lua
  run_check "Resource lifecycle and idle LSP cleanup" 0 nvim --headless --clean -u NONE -l scripts/check-lifecycle.lua
  run_check "Mini Notify progress lifecycle" 0 nvim --headless --clean -u NONE -l scripts/check-notify.lua
  run_check "DAP registry migration" 0 nvim --headless --clean -u NONE -l scripts/check-dap-registry.lua
  run_check "DAP executable discovery" 0 nvim --headless --clean -u NONE -l scripts/check-dap-executables.lua
  run_check "DAP path and project resolution" 1 nvim --headless --clean -u NONE -l scripts/check-dap-project.lua
  benchmark_startup
  profile_startup
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
 "$profile_output"; then
    print_status "CVIM dashboard readiness (profile)" "FAIL"
    sed 's/^/      /' "$profile_output"
    (( FAIL_COUNT += 1 ))
    return
  fi

  print_status "CVIM module profile" "PASS"
  sed -n '1,100p' "$profile_output" | sed 's/^/      /'
}

if command -v nvim >/dev/null 2>&1; then
  run_check "Neovim core and plugin-spec smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-nvim.lua
  run_check "Neovim module smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-integration.lua
  run_check "Resource lifecycle and idle LSP cleanup" 0 nvim --headless --clean -u NONE -l scripts/check-lifecycle.lua
  run_check "Mini Notify progress lifecycle" 0 nvim --headless --clean -u NONE -l scripts/check-notify.lua
  run_check "DAP registry migration" 0 nvim --headless --clean -u NONE -l scripts/check-dap-registry.lua
  run_check "DAP executable discovery" 0 nvim --headless --clean -u NONE -l scripts/check-dap-executables.lua
  run_check "DAP path and project resolution" 1 nvim --headless --clean -u NONE -l scripts/check-dap-project.lua
  benchmark_startup
  profile_startup
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
 "$profile_output"; then
    print_status "CVIM dashboard readiness (profile)" "FAIL"
    sed 's/^/      /' "$profile_output"
    (( FAIL_COUNT += 1 ))
    return
  fi

  print_status "CVIM module profile" "PASS"
  sed -n '1,100p' "$profile_output" | sed 's/^/      /'
}

if command -v nvim >/dev/null 2>&1; then
  run_check "Neovim core and plugin-spec smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-nvim.lua
  run_check "Neovim module smoke tests" 0 nvim --headless --clean -u NONE -l scripts/check-integration.lua
  run_check "Resource lifecycle and idle LSP cleanup" 0 nvim --headless --clean -u NONE -l scripts/check-lifecycle.lua
  run_check "Mini Notify progress lifecycle" 0 nvim --headless --clean -u NONE -l scripts/check-notify.lua
  run_check "DAP registry migration" 0 nvim --headless --clean -u NONE -l scripts/check-dap-registry.lua
  run_check "DAP executable discovery" 0 nvim --headless --clean -u NONE -l scripts/check-dap-executables.lua
  run_check "DAP path and project resolution" 1 nvim --headless --clean -u NONE -l scripts/check-dap-project.lua
  benchmark_startup
  profile_startup
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
