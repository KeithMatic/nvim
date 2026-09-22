# 03: Smart semicolon

**What to build:** smartsemicolon parity. In C-like filetypes (JS, TS, JSX, TSX, C, C++, Rust, CSS/SCSS, Java-like), typing `;` anywhere in a line puts the semicolon at the end of the line instead of at the cursor. If the line already ends with `;`, no second one is added. Typing `;` again immediately afterwards gives a literal semicolon at the original cursor position (for `for (;;)` or strings). In every other filetype `;` behaves normally.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Enabled only for an explicit allow-list of C-like filetypes
- [ ] Test (TS buffer): `;` typed mid-line lands at end of line; cursor behaviour matches smartsemicolon
- [ ] Test (TS buffer): a line already ending in `;` is not doubled
- [ ] Test (TS buffer): a double `;` produces one literal `;` at the original position and no trailing one
- [ ] Test (Python and Lua buffers): `;` is inserted literally at the cursor
- [ ] No semicolon-insertion shortcut variant
