# 04: Reference highlights as underlines

**What to build:** Reference highlights (the marks on other occurrences of the word under the cursor) are underlines with no background, so they fit Transparency. They're set on every theme change, next to the Tint, so every Curated theme and every theme switch keeps them.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The LSP reference groups (text, read, write) have no background and are underlined
- [x] Applied from the theme-change hook
- [x] Test: for each Curated theme, the three groups have no background and are underlined
- [x] Test: after switching theme, the groups are still underlined with no background
- [x] Manual: in a TS file, other uses of a symbol are underlined, not blocked
