# 14: Picker icons

**What to build:** Picker windows show an icon in the search bar and an icon as the list's line pointer, taken from the Icon set, built to the owner's annotated design screenshot.

**Blocked by:** 02 (Icon set)

**Status:** done

- [x] First: ask the owner for the annotated design screenshot and wait for it; don't guess the design
- [x] Search-bar and pointer glyphs come from the Icon set
- [x] Test: the picker's prompt and pointer use the chosen glyphs
- [x] Manual: the picker matches the screenshot

## Comments

- The design: a telescope glyph (`misc.prompt_prefix`) as the search bar's prompt, and a pointer (`misc.selection_caret`) left of the list's cursor row. The pointer is drawn in a `statuscolumn` of the list's own, in the cursor line's colours (lua/picker.lua).
