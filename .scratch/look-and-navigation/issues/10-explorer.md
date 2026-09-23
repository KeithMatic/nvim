# 10: Explorer

**What to build:** neo-tree replaces the Snacks explorer as the Explorer, set up from LazyVim's neo-tree extra with the owner's differences on top. It has a Files tab and a Git tab in its top bar. The Explorer position is one setting (float, left or right; default float). In float mode it is centred with no border. `<leader>o` in float mode opens it on the current file and closes it when pressed again; in docked mode it switches focus between the Explorer and the editor, revealing the current file. `<leader>e`/`<leader>E` keep the extra's behaviour. Dotfiles and git-ignored files are shown, `node_modules` is hidden but reachable, and `.DS_Store`/`thumbs.db` are never shown. It follows file-system changes and fetches git status in the background. The Git tab has the owner's stage/unstage/revert/commit/push keys; ordering, expand/collapse and split keys are kept. Folder and git-status icons come from the Icon set. It follows Transparency, and its cursor line shows the Tint. Docked positions re-balance the other windows when it opens or closes. The holding folder's neo-tree file is deleted.

**Blocked by:** 02 (Icon set)

**Status:** ready-for-agent

- [ ] Snacks explorer replaced by the neo-tree extra; only the owner's differences configured on top
- [ ] Sources: filesystem and git_status, shown as winbar tabs; no buffers source
- [ ] One Explorer position setting, default float, centred and borderless
- [ ] `<leader>o` checked free before binding; behaviour per position as described
- [ ] `NeoTree` added to the Transparency prefixes; the Explorer's cursor-line group replaces the Snacks explorer's in the tinted groups
- [ ] Icons from the Icon set
- [ ] Holding-folder neo-tree file deleted in the same commit
- [ ] Test: in float mode, `<leader>o` opens a borderless centred float with the current file selected; pressing it again closes it
- [ ] Test: in a docked position, `<leader>o` moves focus to the Explorer and back
- [ ] Test: the tabs are exactly Files and Git
- [ ] Test: `NeoTree*` panel groups have no background; the Explorer cursor line has the Tint
- [ ] Test: the boot spec still passes
- [ ] Manual: stage and unstage a file from the Git tab; the icons match the statusline
