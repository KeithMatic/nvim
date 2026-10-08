#!/usr/bin/env bash
# Run the test suite headlessly against this config, inside an isolated XDG sandbox
# (.tests/), so real Neovim config, data, state and cache are never touched.
#
# Usage: tests/run.sh [spec...]   (default: every tests/*_spec.lua)
# Ends with a recap of every failure; the whole run is also saved to .tests/last.log.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
sandbox="$root/.tests"

# One run at a time: runs share the sandbox, so a second one would re-sync the
# config and rewrite the state files and logs under the first one's specs. The
# lock is a symlink to the holder's pid, so taking it and naming it is one step.
lock="$sandbox/lock"
mkdir -p "$sandbox"
if ! ln -s "$$" "$lock" 2>/dev/null; then
  holder="$(readlink "$lock" || true)"
  if kill -0 "$holder" 2>/dev/null; then
    echo "tests/run.sh is already running (pid $holder) and the sandbox is shared: wait for it to finish." >&2
    exit 2
  fi
  rm -f "$lock" # left by a run that was killed
  ln -s "$$" "$lock"
fi
trap 'rm -f "$lock"' EXIT

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

# Neovim's messages (headless, they go to stderr) are kept out of the results,
# in one file per spec: interleaved, they'd break up the result lines.
log="$sandbox/last.log"
messages="$sandbox/messages"
failures="$sandbox/failures.txt"
rm -rf "$messages"
mkdir -p "$messages"
: >"$log"
: >"$failures"

failed=""
for spec in "$@"; do
  spec="$(cd "$(dirname "$spec")" && pwd)/$(basename "$spec")"
  name="${spec#"$root"/}"
  msgs="$messages/$(basename "$spec" .lua).log"
  out="$sandbox/spec.out"
  echo "$name" | tee -a "$log"
  if ! TEST_SPEC="$spec" nvim --headless --cmd "luafile $root/tests/harness.lua" 2>"$msgs" | tee "$out"; then
    failed="$failed $name"
    {
      echo "$name"
      grep -v '^  ok ' "$out" || { echo "  (no result: Neovim exited early; its last messages)"; tail -n 20 "$msgs"; }
      echo "  messages: ${msgs#"$root"/}"
    } >>"$failures"
  fi
  cat "$out" >>"$log"
done

# The recap repeats every failure at the end, so `| tail` is all it takes to read a run.
if [ -n "$failed" ]; then
  {
    echo
    echo "Failures:"
    cat "$failures"
    echo
    echo "$(echo "$failed" | wc -w | tr -d ' ') spec file(s) failed:$failed"
    echo "Full log: ${log#"$root"/}"
  } | tee -a "$log"
  exit 1
fi
echo "All specs passed" | tee -a "$log"
