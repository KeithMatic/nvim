# 15: Statusline polish

**What to build:** Follow-up to 12, from the owner's review of the statusline in use.

1. The filename's colour follows the mode, as the mode icon's does.
2. The filename sits in the centre of the bar (of the space between the left and right items), as its filetype icon, name and extension only: no path, no Breadcrumbs (Trouble's symbols leave the statusline; lspsaga's Breadcrumbs stay in the winbar). It's now shown by default; `<leader>uN` still hides it, and the choice is still remembered.
3. No chevrons between components.
4. The scrollbar's block changes colour as well as size: a different theme colour for each of its eight blocks, graded from top to bottom, and never blank.
5. Pending plugin updates show the Icon set's package glyph (lazy.nvim's own glyph doesn't render) with the count; nothing when there are none.
6. The filetype shows on the right, its colour saying whether a language server is working for the file: the theme's "ok" colour when one is attached, its error colour when one is enabled for the filetype but none is attached (not installed, failed, stopped), and a muted colour when no server exists for the filetype.
7. Only the mode icon and the filename follow the mode. Every other item's icon has its own colour from the current theme, and its text is the theme's soft foreground, the same in every mode.

**Blocked by:** 12

**Status:** done

- [x] Test: the filename is shown by default as name and extension only, with no directory, centred between the left and right items
- [x] Test: `<leader>uN` hides the filename, and a second boot keeps it hidden
- [x] Test: no chevron separators are drawn
- [x] Test: the mode icon and filename take the Mode colours; after switching theme they follow the new theme's
- [x] Test: the other items' icons have distinct colours, and they and their text keep their colours across modes
- [x] Test: the scrollbar's eight blocks each have a different colour, and the last line still shows a block
- [x] Test: with a pending update, the package glyph and count show (in transparency_spec)
- [x] Test: the filetype is the "ok" colour with a server attached, the error colour once it's stopped, and muted for a filetype with no server
- [ ] Manual: the statusline reads well in every Curated theme
