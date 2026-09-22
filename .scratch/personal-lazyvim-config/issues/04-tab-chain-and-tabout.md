# 04: Tab chain + tabout

**What to build:** `<Tab>` behaves like VS Code with the taboutx extension, with one key owner and a guaranteed order: (1) if the completion menu is open, accept the selected item; (2) else if inside a snippet, jump to the next placeholder; (3) else if the character under the cursor is a closer (`)`, `]`, `}`, `"`, `'`, backtick), move past it; (4) else insert normal indentation. `<Enter>` never accepts a completion. `<C-n>`/`<C-p>` and the arrow keys move through the menu. Tabout is my own small module called from the completion engine's Tab chain, not a separate plugin.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The completion engine is the sole owner of insert-mode `<Tab>`; no other plugin maps it
- [ ] Test: with the menu open, `<Tab>` accepts the selected item
- [ ] Test: with the cursor before each closer character and no menu, `<Tab>` moves past it without inserting text
- [ ] Test: in plain text with no menu, `<Tab>` inserts indentation
- [ ] Test: with the menu open, `<Enter>` inserts a newline and accepts nothing
- [ ] Snippet placeholder jumping still works (manual check if not practical headlessly)
