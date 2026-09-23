# Neovim config

A personal LazyVim-based editor: LazyVim's defaults and extras, plus a transparent,
theme-driven look and a handful of VS Code habits carried over.

## Language

### Look

**Curated themes**:
The short list of dark themes the theme picker offers; the last one applied is restored at startup.
_Avoid_: Colorschemes (for the curated list), theme list

**Transparency**:
Panel and float backgrounds cleared so the terminal's glass shows through, whatever the theme.
_Avoid_: Glass, no-background

**Tint**:
The colour faded over the theme's background that marks "where am I" lines: the cursor line, the explorer's line and the selected menu item.
_Avoid_: Cursorline colour, highlight

**Mode colours**:
The theme's colours for insert, visual, delete and copy, shared by the cursor-line tint and the statusline's mode icon.

**Icon set**:
The single collection of glyphs every part of the editor draws from: kinds, diagnostics, gutter signs, file statuses, and extra UI and misc glyphs.
_Avoid_: Icons file, symbols

**Reference highlights**:
The marks on other occurrences of the word under the cursor; shown as an underline, never as a background block.
_Avoid_: Links, word highlights, LSP references

**Cursor trail**:
The animated trail the cursor leaves as it moves; off in Neovide, which animates its own cursor.

### Navigation

**Explorer**:
The file tree, with a Files tab and a Git tab, shown in the Explorer position.
_Avoid_: File tree, sidebar, neo-tree (the plugin, not the concept)

**Explorer position**:
Where the Explorer appears: floating in the centre (the default), or docked left or right.

**Breadcrumbs**:
The path to the symbol under the cursor, shown at the top of the window.
_Avoid_: Winbar, symbol path

**Dashboard**:
The start screen shown when Neovim opens with no file.
_Avoid_: Start page, splash

**Motion hints**:
The keys that reach each spot on the cursor line (w, b, e, ^, $, ...), drawn beneath it; hidden until toggled, for practising motions.
_Avoid_: Precognition (the plugin, not the concept)

### Editing

**Menu keys**:
The Ctrl-h/j/k/l keys that drive an open completion menu (dismiss, next, previous, accept) and move the cursor when none is open.

**Runner**:
Saves the current file and runs it in a reused bottom terminal.
_Avoid_: Code runner, executor

**Smart semicolon**:
A `;` typed mid-line lands at the end of the code; typing it again straight away puts it back where the cursor was.

**Tabout**:
Tab moves the cursor past a closing bracket or quote.
