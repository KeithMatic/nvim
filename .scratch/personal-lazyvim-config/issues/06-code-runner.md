# 06: Code runner

**What to build:** code-runner parity. `<leader>cx` (in LazyVim's existing "code" which-key group) or `:RunFile` saves the current file and runs it with the right command for its filetype, in a bottom split terminal that is reused between runs. Commands: Python → python3, Go → `go run`, JS → node, TS → `deno run`, Lua → `nvim -l`, Rust → `cargo run` inside a Cargo project and otherwise compile the single file then run it, C/C++ → compile with clang/clang++ then run. Compiled binaries go to a temp location, never the project. Unsupported filetypes show a clear "no runner for <ft>" message. A dry-run mode returns the resolved command without running it, for tests.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `<leader>cx` confirmed free in LazyVim before binding; shows in which-key with a description
- [ ] The buffer is saved before running
- [ ] Output appears in one bottom split terminal that is reused on the next run, not duplicated
- [ ] Test (dry-run): the correct command for python, go, javascript, typescript (deno), lua, c and cpp fixtures
- [ ] Test (dry-run): Rust inside a Cargo project resolves to `cargo run`; a standalone `.rs` resolves to compile-then-run
- [ ] Test (dry-run): compiled output paths are outside the project directory
- [ ] Test: an unsupported filetype reports "no runner" and runs nothing
