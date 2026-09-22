#!/usr/bin/env bash
# Run the test suite headlessly against this config, inside an isolated XDG sandbox
# (.tests/), so real Neovim config, data, state and cache are never touched.
#
# Usage: tests/run.sh [spec...]   (default: every tests/*_spec.lua)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
sandbox="$root/.tests"

unset NVIM_APPNAME VIMINIT
export XDG_CONFIG_HOME="$sandbox/config"
export XDG_DATA_HOME="$sandbox/data"
export XDG_STATE_HOME="$sandbox/state"
export XDG_CACHE_HOME="$sandbox/cache"
mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# Test a copy of the working tree, so files the config writes at runtime
# (lazy-lock.json, lazyvim.json) change in the sandbox, not in the repo.
rsync -a --delete --exclude .git --exclude .tests --exclude .scratch "$root/" "$XDG_CONFIG_HOME/nvim/"

# Install plugins at the lockfile's versions, plus the Mason tools and parsers
# LazyVim wants: slow on the first run, then only again when the lockfile changes.
restored="$sandbox/lazy-lock.restored.json"
if ! cmp -s "$root/lazy-lock.json" "$restored"; then
  echo "Setting up the sandbox (lockfile changed)..."
  nvim --headless "+Lazy! restore" "+luafile $root/tests/setup.lua" "$XDG_CONFIG_HOME/nvim/init.lua" >"$sandbox/setup.log" 2>&1 ||
    { cat "$sandbox/setup.log"; exit 1; }
  cp "$root/lazy-lock.json" "$restored"
fi

if [ $# -eq 0 ]; then
  set -- "$root"/tests/*_spec.lua
fi

failed=0
for spec in "$@"; do
  spec="$(cd "$(dirname "$spec")" && pwd)/$(basename "$spec")"
  echo "${spec#"$root"/}"
  TEST_SPEC="$spec" nvim --headless --cmd "luafile $root/tests/harness.lua" || failed=$((failed + 1))
done

if [ "$failed" -ne 0 ]; then
  echo "$failed spec file(s) failed"
  exit 1
fi
echo "All specs passed"
