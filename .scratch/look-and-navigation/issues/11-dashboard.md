# 11: Dashboard

**What to build:** The Dashboard shows the South Park header and a second pane with a colour strip, recent files, projects and git status (git status only inside a git repo). LazyVim's Dashboard keys stay unchanged; only the header and sections are overridden. The colour strip runs only when `colorscript` is available. When it's missing or fails, its space stays empty, the Dashboard shows no error, and one warning notification says what's wrong and how to fix it. While the Dashboard is current there is no cursor and no statusline; both come back when leaving it. The holding folder's snacks file is deleted.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Only the Dashboard's header and sections overridden; LazyVim's keys and pick left alone
- [ ] Colour strip guarded by an executable check; failure gives exactly one WARN notification
- [ ] Cursor hidden and the global statusline removed while the Dashboard is current; both restored on leaving
- [ ] Holding-folder snacks file deleted in the same commit
- [ ] Test: the header matches; the key list equals LazyVim's
- [ ] Test: with `colorscript` absent from `PATH`, the Dashboard opens with no error and exactly one WARN notification
- [ ] Test: while the Dashboard is current the cursor is hidden and `laststatus` is 0; both are restored after opening a file
- [ ] Manual: the layout looks right with and without `colorscript`
