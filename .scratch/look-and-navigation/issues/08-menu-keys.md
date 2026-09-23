# 08: Menu keys

**What to build:** The Menu keys drive completion menus from the home row, in the editor and in the cmdline. With a menu open: Ctrl-j/Ctrl-k select next/previous, Ctrl-l accepts, Ctrl-h closes the menu. With no menu in insert mode: Ctrl-h/j/k/l move the cursor left/down/up/right. With no menu in the cmdline: Ctrl-j/Ctrl-k recall next/previous history and Ctrl-h/Ctrl-l move the cursor. Ctrl-n/Ctrl-p, the Tab chain (accept → snippet forward → Tabout → indent), Shift-Tab (snippet back) and "Enter never accepts" are unchanged. Signature help keeps opening automatically; blink's manual Ctrl-k signature key is replaced.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Editor keymap: the four Menu keys added on top of the `default` preset and the Tab chain
- [x] Cmdline keymap: the four Menu keys with history and cursor fallbacks
- [x] Insert-mode cursor fallbacks keep the move in the current undo step, as Tabout does (left/right only; see Comments)
- [x] Test: with the menu open, Ctrl-j/Ctrl-k change the selection, Ctrl-l inserts the item, Ctrl-h closes the menu
- [x] Test: with no menu in insert mode, each key moves the cursor one step in its direction
- [x] Test: in the cmdline with no menu, Ctrl-k recalls the previous history entry
- [x] Test: the existing Tab-chain spec still passes
- [ ] Manual: the keys feel right in the editor and the noice cmdline

## Comments

- Only Ctrl-h/Ctrl-l keep the move in the current undo step (`<C-g>U<Left>`/`<Right>`, as Tabout does). `<C-g>U` only covers moves within a line, and every vertical move tried (`<Down>`, `<C-g>U<Down>`, `<C-g>j`) starts a new undo step. Moving the cursor from a `<Cmd>` breaks undo outright (undo keeps text typed after the move). So Ctrl-j/Ctrl-k are the plain arrow keys, and split undo as the arrows do.
- LazyVim also maps insert-mode `<c-k>` to signature help in LSP buffers, and that shadows the Menu key when the server attaches after the first insert. That LSP key is removed (noice still opens signature help by itself); a test covers it with lua_ls.
- In the cmdline, blink.cmp ignores keys a function returns, so the fallbacks feed their keys, ahead of anything already queued (a macro, a paste).
- Ctrl-h hides the menu, keeping any previewed item (blink's `hide`, not `cancel`).
