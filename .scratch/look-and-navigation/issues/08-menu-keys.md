# 08: Menu keys

**What to build:** The Menu keys drive completion menus from the home row, in the editor and in the cmdline. With a menu open: Ctrl-j/Ctrl-k select next/previous, Ctrl-l accepts, Ctrl-h closes the menu. With no menu in insert mode: Ctrl-h/j/k/l move the cursor left/down/up/right. With no menu in the cmdline: Ctrl-j/Ctrl-k recall next/previous history and Ctrl-h/Ctrl-l move the cursor. Ctrl-n/Ctrl-p, the Tab chain (accept → snippet forward → Tabout → indent), Shift-Tab (snippet back) and "Enter never accepts" are unchanged. Signature help keeps opening automatically; blink's manual Ctrl-k signature key is replaced.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Editor keymap: the four Menu keys added on top of the `default` preset and the Tab chain
- [ ] Cmdline keymap: the four Menu keys with history and cursor fallbacks
- [ ] Insert-mode cursor fallbacks keep the move in the current undo step, as Tabout does
- [ ] Test: with the menu open, Ctrl-j/Ctrl-k change the selection, Ctrl-l inserts the item, Ctrl-h closes the menu
- [ ] Test: with no menu in insert mode, each key moves the cursor one step in its direction
- [ ] Test: in the cmdline with no menu, Ctrl-k recalls the previous history entry
- [ ] Test: the existing Tab-chain spec still passes
- [ ] Manual: the keys feel right in the editor and the noice cmdline
