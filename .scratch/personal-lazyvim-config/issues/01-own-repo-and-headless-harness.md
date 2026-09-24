# 01: Own the repo + headless test harness

**What to build:** The config becomes clearly mine and testable. The starter's git history is replaced by a fresh repository whose first commit is my own. Leftover template material (example plugin file, starter README, starter licence) is gone, and the plugin lockfile is tracked so every plugin version is pinned. A README explains what this config is, why LazyVim is kept as the base, maps each VS Code extension I used to its Neovim equivalent, and has a Roadmap (html-end-tag-labels; floating-terminal runner). A headless test harness boots the real config inside an isolated XDG sandbox (separate config/data/state/cache) so tests never touch my real Neovim state. This harness is the single seam every later ticket tests through.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Starter git history removed; fresh repo initialised with a first commit on `main`
- [x] Starter example plugin file, README and licence removed; stylua, neoconf and LazyVim JSON state kept
- [x] Plugin lockfile tracked in git
- [x] README contains: purpose, one-sentence rationale for keeping LazyVim, VS Code extension → Neovim equivalent table, Roadmap section
- [x] A single command runs the test suite headlessly in a sandboxed XDG environment (plugins install into the sandbox on first run)
- [x] First test passes: the config boots with no errors or error notifications
- [x] Running the tests leaves the real Neovim state and data directories untouched
