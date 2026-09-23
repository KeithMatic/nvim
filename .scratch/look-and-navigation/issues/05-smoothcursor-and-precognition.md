# 05: smoothcursor and precognition

**What to build:** The smoothcursor trail keeps working as it does now (outside Neovide). precognition is configured properly (through `opts`, not a `config` table), hidden at startup, and shown or hidden with `<leader>uP` from LazyVim's UI toggle group. This finishes the matching part of the uncommitted UI experiments, with their lockfile entries.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Confirm with the owner: precognition hidden by default with a `<leader>uP` toggle (the spec's recommendation)
- [ ] `<leader>uP` checked free before binding
- [ ] precognition configured through `opts`; the commented-out settings removed
- [ ] smoothcursor unchanged: autostart, fancy mode, disabled in Neovide
- [ ] Lockfile entries for these two plugins only
- [ ] Test: precognition is hidden after boot; `<leader>uP` shows it and pressing it again hides it
- [ ] Test: the boot spec still passes
- [ ] Manual: the cursor trail animates; precognition hints appear only after the toggle
