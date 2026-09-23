Status: ready-for-agent

# Look and navigation: Explorer, Dashboard, statusline, Icon set, Menu keys

## Problem Statement

My config works and is transparent over the glass, but it doesn't yet look or move the way I want. Several pieces I collected are half-integrated: a neo-tree config, a Snacks dashboard and an old statusline sit unused in a holding folder, a big icons file is required by nothing, and uncommitted UI experiments (smoothcursor, precognition, lspsaga, noice) are partly broken: precognition is configured in a way that only works by accident, lspsaga turns on features that duplicate LazyVim's, and the noice settings I wrote are silently ignored. Neovim also showed an error on every start (nvim-dap failing to configure).

Day to day, small things grate. Other occurrences of the word under the cursor are painted with solid background blocks that break the transparent look. The TOML file icon doesn't render anywhere (explorer, statusline, picker, bufferline). The Dashboard shows a cursor it doesn't need and a statusline with nothing to say. The file explorer has no Git view. Moving through completion menus means stretching for Ctrl-n/Ctrl-p, and leaving insert mode means reaching for Escape. I've also found sqmeow.nvim, which looks like a better database client than what I have, and I want to try it.

## Solution

Finish integrating what I collected, fix what's broken, and add a small set of navigation and editing conveniences, while changing nothing that doesn't need changing:

- Neovim starts without errors, with a working debugger.
- One **Icon set** is the source of every glyph in the editor, and any file can use it.
- The TOML icon renders everywhere.
- **Reference highlights** are underlines, not background blocks.
- The **Explorer** is neo-tree with a Files tab and a Git tab, floating in the centre without a border by default, with a configurable **Explorer position** and a `<leader>o` key that reveals the current file.
- The **Dashboard** gets my South Park header and a second pane (colours, recent files, projects, git status), with no cursor and no statusline.
- The statusline gains the components I liked from my old one, coloured from the theme instead of hard-coded, with an optional filename I can toggle.
- The noice cmdline sits in the centre of the screen with icons, visually separated from its completion menu.
- lspsaga provides only **Breadcrumbs**, rename and outline; smoothcursor and precognition work properly.
- The **Menu keys** (Ctrl-h/j/k/l) drive completion menus and move the cursor otherwise; `jj`/`jk` leave insert mode.
- sqmeow.nvim is tried as the database client, keeping SQL completion.
- Picker windows get icons on the search bar and the list pointer, to a design I'll provide.

## User Stories

### Startup and debugging
1. As the config owner, I want Neovim to start without the nvim-dap configuration error, so that every session starts clean.
2. As the config owner, I want a working debugger for the languages whose extras already configure debug adapters (Python, Go, C/C++, Rust), so that the adapters I already have installed are usable instead of half-loaded.
3. As the config owner, I want the debugger's panels to follow Transparency while the line the debugger stopped on stays solid, so that debugging matches the rest of the UI.

### Icon set
4. As the config owner, I want one Icon set that every plugin draws from, so that the same concept (an error, a modified file, a function) always has the same glyph.
5. As the config owner, I want the Icon set to feed LazyVim's own icon options, so that completion kinds, diagnostics, gutter signs, the statusline, Trouble and which-key all use it without per-plugin wiring.
6. As the config owner, I want any of my own files to be able to use the Icon set directly, so that new features don't copy glyphs around.
7. As the config owner, I want completion kind icons taken from my `kind` group, so that the menu uses the set I curated.
8. As the config owner, I want diagnostic icons taken from my `diagnostics` group, so that signs, the statusline and Trouble agree.
9. As the config owner, I want gutter git signs taken from my line-added/modified/removed icons, so that the sign column uses my glyphs.
10. As the config owner, I want file-status icons (added, deleted, modified, renamed, untracked, ignored, unstaged, staged, conflict) taken from my neo-tree symbols, so that the Explorer and statusline show the same file states the same way.
11. As the config owner, I want only true duplicates removed from the Icon set, so that no glyph I picked disappears.
12. As the config owner, I want my `ui` and `misc` glyphs kept as extra groups, so that they're available for later features.

### TOML icon
13. As the config owner, I want TOML files to show a glyph that actually renders in my terminal, so that TOML files aren't blank in the Explorer, statusline, picker and bufferline.
14. As the config owner, I want to choose the TOML glyph from a few candidates shown in my terminal, so that I pick one I can see renders.
15. As the config owner, I want the TOML fix to apply by extension and by filetype, so that Cargo.toml, pyproject.toml and any other .toml file are all covered.

### Reference highlights
16. As the config owner, I want other occurrences of the word under the cursor to be underlined instead of painted with a background, so that they fit Transparency.
17. As the config owner, I want Reference highlights to keep their underline after I switch theme, so that a theme change doesn't bring the background blocks back.
18. As the config owner, I want Reference highlights to stay visible, so that I still see where else a symbol is used.

### UI experiments (smoothcursor, precognition, lspsaga)
19. As the config owner, I want smoothcursor's animated cursor trail kept as it is, outside Neovide, so that I keep the effect I like.
20. As the config owner, I want precognition configured properly and hidden by default, so that motion hints don't clutter the screen while I type.
21. As the config owner, I want a toggle key for precognition, so that I can show motion hints when I want to practise.
22. As the config owner, I want lspsaga's Breadcrumbs at the top of the window, so that I can see which symbol I'm inside.
23. As the config owner, I want to toggle Breadcrumbs with `<leader>kb`, so that I can hide them when I need the space.
24. As the config owner, I want `<leader>kr` to rename with lspsaga, so that I get lspsaga's rename UI alongside LazyVim's rename on `<leader>cr`.
25. As the config owner, I want `<leader>ko` to open lspsaga's outline, so that I get a symbol outline alongside Trouble's symbols on `<leader>cs`.
26. As the config owner, I want LazyVim's `<leader>cr`, `<leader>cs` and `<leader>cS` kept, so that I don't lose them.
27. As the config owner, I want lspsaga's keys grouped under a `<leader>k` "lspsaga" group in which-key, so that I can browse to them.
28. As the config owner, I want lspsaga's lightbulb, hover, code actions, diagnostics and finder turned off, so that they don't duplicate what LazyVim already gives me.
29. As the config owner, I want lspsaga's windows to follow Transparency, so that its floats don't paint solid backgrounds.

### Noice cmdline
30. As the config owner, I want the cmdline popup in the exact centre of the screen, so that my eyes don't have to move to the top.
31. As the config owner, I want each cmdline kind (command, search, Lua, help, filter, shell) to show its icon from the Icon set, so that the cmdline matches everything else.
32. As the config owner, I want the cmdline's completion menu one row below the cmdline's border, so that the two borders don't overlap.

### Menu keys and escape
33. As the config owner, I want Ctrl-l to accept the selected completion item, so that I can accept without Tab or Enter.
34. As the config owner, I want Ctrl-l to move the cursor right when no menu is open, so that the key is still useful in insert mode.
35. As the config owner, I want Ctrl-h to close the completion menu, so that I can dismiss suggestions from the home row.
36. As the config owner, I want Ctrl-h to move the cursor left when no menu is open, so that h and l mirror each other.
37. As the config owner, I want Ctrl-j/Ctrl-k to select the next/previous menu item, so that I can move through menus from the home row.
38. As the config owner, I want Ctrl-j/Ctrl-k to move the cursor down/up in insert mode when no menu is open, so that they behave like j and k.
39. As the config owner, I want the same Menu keys in the cmdline's completion menu, so that menus behave the same everywhere.
40. As the config owner, I want Ctrl-j/Ctrl-k in the cmdline with no menu to recall the next/previous history entry, so that they act like the arrow keys.
41. As the config owner, I want Ctrl-h/Ctrl-l in the cmdline with no menu to move the cursor left/right, so that they behave the same as in insert mode.
42. As the config owner, I want Ctrl-n/Ctrl-p to keep working in menus, so that both habits work.
43. As the config owner, I want my Tab chain (accept → snippet forward → Tabout → indent) and Shift-Tab (snippet back) unchanged, and Enter never to accept, so that nothing I rely on breaks.
44. As the config owner, I want signature help to keep opening automatically, so that losing blink's manual Ctrl-k signature key costs nothing.
45. As the config owner, I want `jj` and `jk` to leave insert mode and cmdline mode, so that I don't have to reach for Escape.
46. As the config owner, I want typing `j` not to pause on screen while the escape waits for a second key, so that normal typing feels instant.
47. As the config owner, I want the escape sequence limited to insert and cmdline modes, so that `j` still moves in visual mode and `jj` still reaches programs in the terminal (e.g. lazygit).

### Explorer
48. As the config owner, I want neo-tree as my Explorer instead of the Snacks explorer, so that I get its Git view and file-state features.
49. As the config owner, I want the Explorer set up from LazyVim's neo-tree extra, with only my differences on top, so that I keep receiving the extra's upstream fixes.
50. As the config owner, I want a Files tab and a Git tab in the Explorer's top bar, so that I can switch between the file tree and changed files.
51. As the config owner, I want the Explorer to float in the centre of the screen by default, so that it doesn't permanently take space from the editor.
52. As the config owner, I want the floating Explorer to have no border for now, so that it matches my borderless look (I may add one back later).
53. As the config owner, I want one Explorer position setting (float, left or right), so that I can dock it without rewriting the config.
54. As the config owner, I want `<leader>o` in float mode to open the Explorer showing the current file, and close it when pressed again, so that one key shows me where I am.
55. As the config owner, I want `<leader>o` in left/right mode to switch focus between the Explorer and the editor, revealing the current file, so that I can jump back and forth without closing it.
56. As the config owner, I want `<leader>e`/`<leader>E` to keep LazyVim's behaviour, so that existing muscle memory still works.
57. As the config owner, I want dotfiles and git-ignored files shown, `node_modules` hidden but reachable, and `.DS_Store`/`thumbs.db` never shown, so that I see what matters.
58. As the config owner, I want the Explorer to update on file-system changes and fetch git status in the background, so that it's current without slowing the editor.
59. As the config owner, I want to stage, unstage, revert, commit and push from the Git tab (with my `A`, `ga`, `gu`, `gr`, `gc`, `gp`, `gg` keys), so that small git tasks don't need another tool.
60. As the config owner, I want the ordering keys (`o` then c/d/m/n/s/t) and the expand/collapse (`Z`/`z`) and split (`s`/`S`) keys from my config, so that the Explorer behaves the way I set it up.
61. As the config owner, I want the Explorer's folder and git-status icons to come from the Icon set, so that they match the statusline.
62. As the config owner, I want the Explorer to follow Transparency, with its cursor line showing my Tint, so that it looks like the rest of the UI.
63. As the config owner, I want the other windows re-balanced when a docked Explorer opens or closes, so that splits stay even.

### Dashboard
64. As the config owner, I want my South Park header on the Dashboard, so that the start screen feels like mine.
65. As the config owner, I want a second pane with recent files, projects and git status (the last only inside a git repo), so that I can jump straight into recent work.
66. As the config owner, I want a colour-strip terminal section on the Dashboard, so that it has some colour.
67. As the config owner, I want the colour strip to leave its space empty, with no error on the Dashboard, when `colorscript` is missing or fails, so that a missing tool never breaks the start screen.
68. As the config owner, I want a notification naming the problem when the colour strip can't run, so that I know what to fix.
69. As the config owner, I want LazyVim's Dashboard keys (find file, new file, find text, recent files, config, restore session, extras, Lazy, quit) unchanged, so that only what I asked for changes.
70. As the config owner, I want no cursor on the Dashboard, so that nothing distracts from the visible shortcuts.
71. As the config owner, I want no statusline on the Dashboard, so that the start screen is clean.
72. As the config owner, I want the cursor and statusline back as soon as I leave the Dashboard, so that editing is unaffected.

### Statusline
73. As the config owner, I want a mode icon from the Icon set, coloured with the Mode colours, so that I can see the mode at a glance.
74. As the config owner, I want the file size shown, so that I notice large files.
75. As the config owner, I want diagnostics counts shown, so that I know the file's health.
76. As the config owner, I want lualine-so-fancy's diff shown, so that I see my uncommitted line changes.
77. As the config owner, I want the Python virtual environment shown in Python files, so that I know which interpreter is active.
78. As the config owner, I want the pending plugin updates, git branch, progress/location and a scrollbar on the right, so that the right side carries the same information as my old statusline.
79. As the config owner, I want every statusline colour taken from the current theme, so that it follows theme changes instead of using hard-coded hex values.
80. As the config owner, I want the filename, with its filetype icon in the icon's own colour, available but off by default, so that I can see it without duplicating the Breadcrumbs.
81. As the config owner, I want to toggle the filename with `<leader>uN` and have the choice remembered across restarts, so that I set it once.
82. As the config owner, I want the statusline empty while the Explorer is focused, so that it doesn't show the Explorer's own details (I may go back to the default).

### Database client
83. As the config owner, I want to try sqmeow.nvim as my database client, so that queries run without freezing the editor and results are pageable, editable and exportable.
84. As the config owner, I want sqmeow's engine installed automatically when the plugin is installed or updated, so that there's no manual setup.
85. As the config owner, I want SQL table and column completion in `.sql` files kept, so that I don't lose completion by switching clients.
86. As the config owner, I want the old database UI turned off, so that there aren't two database UIs.
87. As the config owner, I want going back to the old client to be a one-line change, so that trying sqmeow carries no risk.

### Picker icons
88. As the config owner, I want an icon in picker windows' search bar, so that pickers match my design.
89. As the config owner, I want an icon as the picker list's line pointer, so that the selected entry is obvious.
90. As the config owner, I want to be asked for my annotated design screenshot when this work starts, so that it's built to my design rather than guessed.

### Housekeeping
91. As the config owner, I want each file in the holding folder deleted once it has been implemented, so that no half-integrated config is left lying around.
92. As the config owner, I want one commit per change, each checked by the headless test suite and by me, so that any change can be reverted on its own.
93. As the config owner, I want the project glossary kept up to date with the terms these features introduce, so that the config's language stays consistent.

## Implementation Decisions

- **Debugger (done):** LazyVim's `dap.core` extra is enabled. The root cause was that nvim-dap-python's own package spec makes nvim-dap a required dependency, overriding the language extras' `optional` flag, so nvim-dap loaded with their options but no config. No Transparency changes were needed: dap-ui panels use Normal, and `DapStoppedLine` is a "where am I" line that correctly keeps its background.
- **Icon set:** a single shared Lua module in the config's own utility namespace, restructured into LazyVim's icon layout (`diagnostics`, `git`, `kinds`, plus whatever other groups LazyVim reads), with extra groups for file status, modes, `ui`, `misc` and separators. It is passed to LazyVim's `icons` option so everything LazyVim wires gets it. Anything else requires the module directly. Which entry wins: kinds from `kind`; diagnostics from `diagnostics`; gutter signs from the git line-added/modified/removed entries; file statuses from the neo-tree symbols. Only exact duplicates of those are removed. Top-level loose entries are folded into the matching group. Inconsistent padding (e.g. entries with three trailing spaces) is normalised to the layout's convention.
- **TOML glyph:** an override in mini.icons (LazyVim's icon provider, which also stands in for nvim-web-devicons) for the `toml` extension and filetype. The default glyph (U+E6B2) is missing from the target terminal's symbol fallback font. The replacement is chosen by the owner from three candidates rendered in the target terminal.
- **Reference highlights:** the LSP reference groups (text, read, write) lose their background and gain an underline. This is set from the theme module's theme-change hook, next to the Tint, so it survives every theme switch and applies to all Curated themes.
- **precognition:** configured through `opts`, not visible at startup, with a toggle key in LazyVim's UI toggle group (`<leader>uP`, confirmed free before binding).
- **smoothcursor:** unchanged: enabled outside Neovide, fancy mode, starts automatically.
- **lspsaga:** set up with only symbol-in-winbar (Breadcrumbs), rename and outline enabled; lightbulb, hover, code action, diagnostic and finder disabled. Keys, under a which-key "lspsaga" group on the free `<leader>k` prefix: `<leader>kr` (rename), `<leader>ko` (outline), `<leader>kb` (Breadcrumbs toggle). LazyVim's `<leader>cr` and Trouble's `<leader>cs`/`<leader>cS` are untouched. `Saga` joins the Transparency prefix list.
- **Noice:** the popup position/size settings move to noice's top-level `views` (where they take effect, unlike the ignored preset-nested table). The cmdline popup is centred on both axes. Cmdline format icons come from the Icon set. The completion menu is placed one row below the popup's bottom border by offsetting blink's cmdline menu position from noice's reported cmdline position.
- **Menu keys (blink.cmp):** the editor keymap keeps the `default` preset and the Tab chain, and adds: Ctrl-l = accept, else cursor right; Ctrl-h = hide menu, else cursor left; Ctrl-j = next item, else cursor down; Ctrl-k = previous item, else cursor up (replacing the preset's signature toggle). The cmdline keymap adds: Ctrl-j/Ctrl-k = next/previous item, else history next/previous; Ctrl-h/Ctrl-l = hide/accept, else cursor left/right. Ctrl-n/Ctrl-p, Shift-Tab (snippet back) and the Enter behaviour are unchanged. Cursor fallbacks use undo-safe insert-mode motions, as Tabout does.
- **Better escape:** better-escape.nvim with `jj` and `jk` in insert and cmdline modes only (not visual, select or terminal), with a 200 ms window.
- **Explorer:** the Snacks explorer is replaced by LazyVim's `editor.neo-tree` extra. The owner's neo-tree config is ported as a delta over the extra: sources are filesystem and git_status (the buffers source is dropped), shown as tabs in a winbar source selector; filtered items as listed in the user stories; libuv file watcher; async git status; modified markers, diagnostics, symlink targets and case-insensitive sorting on; indent markers and expanders; git_status window keys as in the owner's config. The Explorer position is one setting at the top of the Explorer's plugin spec (`float` | `left` | `right`, default `float`). Float mode is centred with no border. Window equalisation on open/close applies only to docked positions. `<leader>o` behaviour depends on the position (see user stories 54–55); `<leader>e`/`<leader>E` keep the extra's behaviour. `NeoTree` joins the Transparency prefixes, and the Explorer's cursor-line group joins the tinted groups (replacing the Snacks explorer's).
- **Dashboard:** LazyVim's Snacks dashboard options are overridden only for `preset.header` and `sections`. LazyVim's `keys` and `pick` are left alone. The colour strip is a terminal section enabled only when `colorscript` is executable. When it's missing or exits non-zero, its space is left empty and a single WARN notification names the problem and how to fix it. While a Dashboard window is current, the cursor is hidden and the global statusline is removed (`laststatus` 0); both are restored when leaving the Dashboard.
- **Statusline:** builds on the existing theme-driven lualine `opts` function and its transparent theme, without replacing LazyVim's sections wholesale. Added: mode icon (Icon set) coloured from the theme module's Mode colours; file size; diagnostics (already present); lualine-so-fancy diff; Python venv; lazy updates (already present); branch; progress/location; scrollbar. The filename component (with its filetype icon in the icon's own colour) is controlled by a toggle stored in the theme module's state file alongside the theme and Tint. With the global statusline, the bar is blank while the Explorer is focused.
- **Database client:** sqmeow.nvim is added (nui.nvim dependency, release-versioned, engine installed by its build hook, loaded on its command). From the `lang.sql` extra, vim-dadbod-ui is disabled; vim-dadbod and vim-dadbod-completion stay for blink's SQL completion source.
- **Picker icons:** Snacks picker's prompt icon and list pointer come from the Icon set, to the owner's annotated screenshot. The design is requested before this work starts; nothing is guessed.
- **Holding folder:** each file in `to-add/` is deleted in the same commit that implements it. The folder goes when it's empty.
- **Key changes to LazyVim defaults** (supersedes the previous spec's "only `<leader>uC`" rule): blink's Ctrl-k in insert mode (and LazyVim's LSP signature-help Ctrl-k, which would shadow it), and the Snacks explorer replaced by neo-tree. New keys: `<leader>o`, the `<leader>k` lspsaga group (`kr`, `ko`, `kb`), `<leader>uN`, `<leader>uP`, and the Menu keys and `jj`/`jk` above. Each new key is checked free before binding.

## Testing Decisions

- **One seam, the existing one:** the headless harness (`tests/run.sh` plus the harness module) boots the real config in the isolated XDG sandbox and runs one spec file per behaviour. No new seam is introduced, and no test reaches into a module's local functions.
- **What a good test looks like:** drive the editor as a user would (feed keys, run commands, open files, apply themes, start a second instance), then assert on what the user would see: buffer text, cursor position, mode, highlight attributes, window/float configuration, statusline content, notifications, state after a restart. Tests must not care how a behaviour is implemented.
- **Covered behaviours:**
  - Boot: no errors or error notifications with every new plugin enabled (the existing boot spec, which now also covers the debugger).
  - Icon set: LazyVim's icon options hold the chosen glyphs for a sample of kinds, diagnostics and git signs; the module can be required on its own.
  - TOML: mini.icons returns the chosen glyph for `Cargo.toml` and for the `toml` filetype.
  - Reference highlights: for each Curated theme, the three LSP reference groups have no background and are underlined.
  - lspsaga: `<leader>kr`, `<leader>ko`, `<leader>kb` map to lspsaga under a `<leader>k` which-key group, and `<leader>cr`, `<leader>cs`, `<leader>cS` stay LazyVim's; the disabled features register no keys or autocmds; `Saga*` groups have no background.
  - Noice: the cmdline popup is centred; the completion menu's top row is one row below the popup's bottom border.
  - Menu keys: with a menu open, Ctrl-j/Ctrl-k change the selection, Ctrl-l inserts the item, Ctrl-h closes the menu; with no menu, each moves the cursor; in the cmdline, Ctrl-j/Ctrl-k with no menu recall history. The existing Tab-chain spec still passes.
  - Better escape: `jk` and `jj` return to normal mode with neither letter left in the buffer; a lone `j` followed by another letter is inserted as typed; `jj` in visual mode moves the cursor.
  - Explorer: with position float, `<leader>o` opens a borderless centred float with the current file's node selected, and pressing it again closes it; with a docked position, `<leader>o` switches focus and back; the source selector has exactly Files and Git; `NeoTree*` panels have no background; the Explorer cursor line has the Tint.
  - Dashboard: the header matches; the key list equals LazyVim's; with `colorscript` absent from `PATH`, the Dashboard opens with no error and exactly one WARN notification; while the Dashboard is current the cursor is hidden and `laststatus` is 0, and both are restored after opening a file.
  - Statusline: the rendered statusline contains the mode icon, file size, branch and diff for a file in a git repo; `<leader>uN` adds the filename, and the choice survives a second boot; the statusline is blank while the Explorer is focused.
  - Database client: `:Sqmeow` exists; dadbod-ui's commands don't; blink offers dadbod completion in a `.sql` buffer.
  - Picker icons: the picker prompt and pointer use the chosen glyphs.
- **Not tested automatically:** things that can only be judged by eye (animations, whether a glyph actually renders, whether the noice gap looks right). These stay manual checks listed in each ticket.
- **Prior art:** `tint_spec` (highlight assertions across Curated themes, persistence across a second boot, state-file isolation), `tab_spec` (driving the completion menu with fed keys), `semicolon_spec` (insert-mode key behaviour and cursor position), `transparency_spec` (background assertions per group), `boot_spec` (startup error collection), `runner_spec` (observable results without side effects).

## Out of Scope

- Turning `cursorline` off in the editor. The Tint and modes.nvim both colour the cursor line, so this is deferred until it can be rethought.
- neo-tree's buffers source (bufferline already shows open buffers), and customising the Snacks explorer.
- lspsaga features other than Breadcrumbs, rename and outline.
- A manual signature-help key.
- Fixing the terminal's symbol font fallback (the TOML fix is an icon override).
- Picker changes beyond the search-bar icon and list pointer.
- AI completion or chat.
- Borders on the floating Explorer (may return later).

## Further Notes

- This spec supersedes two out-of-scope items of the earlier `personal-lazyvim-config` spec: the debugger (now enabled) and "no changes to LazyVim's default keys other than `<leader>uC`" (see Implementation Decisions).
- The debugger work is already committed and verified by the boot spec. Its ticket can be created as done.
- Target terminal: WezTerm with Operator Mono SSm Lig and a "Symbols Nerd Font Mono" fallback. Glyph choices are checked there.
- The terminal can't do a 1px gap: the separation between the cmdline and its menu is one character row.
- precognition hidden by default with a `<leader>uP` toggle was the recommendation; the owner's answer ("fix and keep it") didn't explicitly confirm the toggle. Confirm when implementing.
- sqmeow.nvim is young (≈114 stars, ≈127 commits at the time of writing) and downloads a native engine at build time. Treat it as a trial.
- The statusline should be blank while the Explorer is focused, but the owner may revert this to LazyVim's default behaviour.
- `test.ts` at the repo root is the owner's scratch file; leave it alone.
