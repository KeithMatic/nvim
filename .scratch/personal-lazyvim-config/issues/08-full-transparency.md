# 08: Full transparency

**What to build:** Everything is transparent over WezTerm's blurred glass: editor, sign column, line numbers, end-of-buffer area, sidebars, file explorer, bufferline, statusline, and every floating window (pickers, which-key, hover and signature docs, completion menu and docs, Lazy, Mason, notifications). Every float gets a rounded border so it stays readable. The statusline shows the current mode as mode-coloured text instead of a solid pill, and shows a count of pending plugin updates. The update checker stays silent. Transparency is applied again every time a theme loads, so switching themes never brings back solid backgrounds. Before clearing, the theme's original editor background is recorded for ticket 09 to blend against.

**Blocked by:** 07

**Status:** ready-for-agent

- [ ] Both themes use their native transparency options; the theme-change hook clears the remaining groups and prefixes
- [ ] The theme's original Normal background is recorded before clearing
- [ ] Rounded borders on all float types listed above
- [ ] The statusline mode component uses coloured foreground on a transparent background; the pending-updates count is visible when updates exist
- [ ] Update checker enabled with notifications off
- [ ] Test: for each of the six themes, Normal, NormalFloat, SignColumn, StatusLine, explorer, bufferline and statusline section groups have no background
- [ ] Test: for each theme, CursorLine and Visual still have a background (not cleared)
