# 05: smoothcursor and precognition

**What to build:** The smoothcursor trail keeps working as it does now (outside Neovide). precognition is configured properly (through `opts`, not a `config` table), hidden at startup, and shown or hidden with `<leader>uP` from LazyVim's UI toggle group. This finishes the matching part of the uncommitted UI experiments, with their lockfile entries.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Confirm with the owner: precognition hidden by default with a `<leader>uP` toggle (the spec's recommendation)
- [x] `<leader>uP` checked free before binding
- [x] precognition configured through `opts`; the commented-out settings removed
- [x] smoothcursor unchanged: autostart, fancy mode, disabled in Neovide
- [x] Lockfile entries for these two plugins only
- [x] Test: precognition is hidden after boot; `<leader>uP` shows it and pressing it again hides it
- [x] Test: the boot spec still passes
- [ ] Manual: the cursor trail animates; precognition hints appear only after the toggle

## Comments

- Owner confirmed: hidden by default, toggled with `<leader>uP`. The key had no mapping before binding (the spec's keymap test failed with no mappings before the toggle was added).
- precognition's `hide()` clears its own augroup, dropping the `ColorScheme` autocmd that restores the hints' highlight; the toggle hides by re-running `setup(opts)` instead. Covered by a test.
