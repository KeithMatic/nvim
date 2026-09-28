# Neovim config

A personal LazyVim-based editor: LazyVim's defaults and extras, plus a transparent,
theme-driven look and a handful of VS Code habits carried over.

## Language

### Look

**Curated themes**:
The short list of dark themes the theme picker offers; the last one applied is restored at startup.
_Avoid_: Colorschemes (for the curated list), theme list

**Transparency**:
Panel and float backgrounds cleared so the terminal's glass shows through, whatever the theme; also
the **In-text blocks**, which keep only their colour.
_Avoid_: Glass, no-background

**In-text blocks**:
Highlights drawn inside the text as a solid block: diagnostics at the end of a line, inlay hints, and
Markdown heading bars, inline code and code blocks.
_Avoid_: Chips (those are accents that keep their background)

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

**Rainbow brackets**:
Bracket pairs coloured by how deeply they nest, cycling the theme's yellow, purple and blue; `( )`,
`[ ]`, `{ }`, and `< >` only where they really are brackets (templates, generics, tags), never
`<<`, a comparison, or an `#include`'s angle brackets. Always on.
_Avoid_: Bracket pair colourisation, rainbow-delimiters (the plugin, not the concept)

**Block guide**:
The single dotted line drawn down the block the cursor is in (its bracket lines included), in a faint
shade of that block's **Rainbow brackets**, and animated in from the cursor except while typing. A block is
any indented body, braces or not; outer blocks show no guide. Only in code, never in prose or tool panels.
_Avoid_: Indent guides, scope

**Cursor trail**:
The animated trail the cursor leaves as it moves; off in Neovide, which animates its own cursor.

### Navigation

**Explorer**:
The file tree, under a single centred Files tab, shown in the Explorer position; its Git view opens on its own (<leader>ge).
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

### Tools

**Database client**:
The one database UI: connections, the Database drawer, and results that page, edit and export. SQL table and column completion in `.sql` files doesn't depend on it.
_Avoid_: DBUI, sqmeow, dadbod (the plugins, not the concept)

**Database drawer**:
The Database client's tree of connections and their schemas, docked on the left; opening it from the Database client's keys puts the cursor in it, and one key (<leader>0) jumps to it and back.
_Avoid_: sqmeow drawer, database explorer, Explorer (that's the file tree)
