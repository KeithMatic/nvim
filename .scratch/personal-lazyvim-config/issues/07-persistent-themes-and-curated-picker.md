# 07: Persistent themes + curated picker

**What to build:** tokyonight and catppuccin are available. LazyVim's `<leader>uC` colorscheme picker, with live preview, lists only my six dark themes: catppuccin frappe, macchiato and mocha; tokyonight night, storm and moon. Whichever theme I last applied, from the picker or by typing the colorscheme command, is saved to a small state file and restored at startup. If the saved theme is missing or invalid, startup falls back to a default (tokyonight-moon) without errors. This introduces my own theme module, with a hook that runs on every theme change; tickets 08 and 09 build on that hook.

**Blocked by:** 01

**Status:** done

- [x] `<leader>uC` opens a previewing picker listing exactly the six curated themes; this is the only change to an existing LazyVim key
- [x] Saving happens in the theme-change hook, so any way of switching theme is persisted
- [x] Test: the picker source yields exactly the six curated names, no light themes
- [x] Test: applying a theme, then booting a second headless instance, restores that theme
- [x] Test: a corrupt or unknown saved theme falls back to the default with no error
- [x] State lives in Neovim's state directory (sandboxed in tests)
