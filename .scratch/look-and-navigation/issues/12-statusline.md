# 12: Statusline

**What to build:** The statusline builds on the existing theme-driven setup and gains the parts the owner liked from their old one. Left: a mode icon from the Icon set, coloured with the Mode colours; file size; diagnostics; lualine-so-fancy's diff. Right: the Python virtual environment (in Python files), pending plugin updates, git branch, progress/location and a scrollbar. Every colour comes from the current theme, never hard-coded. The filename, with its filetype icon in the icon's own colour, is off by default; `<leader>uN` toggles it and the choice is remembered across restarts, saved alongside the theme and Tint. The bar is blank while the Explorer is focused (the owner may revert this to LazyVim's default). The holding folder's lualine file is deleted, and the folder with it.

**Blocked by:** 02 (Icon set), 10 (Explorer)

**Status:** ready-for-agent

- [ ] Components added to the existing lualine options, not a replacement config
- [ ] Mode colours exposed by the theme module for the mode icon
- [ ] `<leader>uN` checked free before binding; the toggle is saved in the theme state
- [ ] Blank bar while the Explorer is focused
- [ ] Holding-folder lualine file and the empty holding folder deleted in the same commit
- [ ] Test: for a file in a git repo, the rendered statusline contains the mode icon, file size, branch and diff
- [ ] Test: `<leader>uN` adds the filename, and a second boot keeps it
- [ ] Test: the statusline is blank while the Explorer is focused
- [ ] Test: after switching theme, the mode icon's colour follows the new theme's Mode colours
- [ ] Manual: the statusline reads well in every Curated theme
