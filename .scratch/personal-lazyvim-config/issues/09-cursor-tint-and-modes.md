# 09: Cursor tint + modes

**What to build:** The "where am I" indicators are solid, faded bars over the glass. The normal-mode cursor line, the file explorer's cursor line and the selected completion item use my tint: a colour blended with the theme's original background at a fade amount, giving a solid hex background. modes.nvim tints the cursor line and visual selection by mode (insert, visual, delete, yank), with colours taken from the active theme's palette at a consistent opacity. `:Tint <hex> <fade>` validates its input, applies immediately, is saved alongside the theme, and survives restarts and theme switches. Invalid input gives a clear error and changes nothing.

**Blocked by:** 08

**Status:** done

- [x] The tint is applied from the theme-change hook, so it survives theme switches
- [x] modes.nvim installed; mode colours derive from the active theme's palette
- [x] Test: after `:Tint #ff0000 0.3`, CursorLine, the explorer cursor-line group and the completion-selection group all have the expected blended background
- [x] Test: the tint persists after booting a second headless instance
- [x] Test: the tint persists after switching theme (blended against the new theme's background)
- [x] Test: invalid hex or an out-of-range fade produces an error and leaves the highlights unchanged
- [x] A sensible default tint on first launch
