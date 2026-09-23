# 02: Icon set

**What to build:** One Icon set is the source of every glyph. It is reshaped into LazyVim's icon layout and passed to LazyVim's icon options, so completion kinds, diagnostics, gutter signs, the statusline, Trouble and which-key all show the owner's glyphs. Any other file can require it directly. Kinds come from the `kind` group, diagnostics from `diagnostics`, gutter signs from the git line-added/modified/removed entries, and file statuses from the neo-tree symbols. `ui`, `misc`, mode icons and separators stay as extra groups. Only exact duplicates are removed; no chosen glyph disappears. This ticket also commits the project glossary and this spec.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The Icon set is a shared module in the config's utility namespace, requirable on its own
- [x] LazyVim's icon options are the Icon set's groups
- [x] File-status glyphs are the neo-tree symbols (added, deleted, modified, renamed, untracked, ignored, unstaged, staged, conflict)
- [x] Only exact duplicates removed; padding normalised to LazyVim's convention
- [x] Test: LazyVim's icon options hold the chosen glyphs for a sample of kinds, diagnostics and git signs
- [x] Test: the module can be required without the rest of the config
- [x] Test: the boot spec still passes
- [x] Glossary and spec committed with this ticket
- [ ] Manual: the completion menu, sign column and which-key show the new glyphs
