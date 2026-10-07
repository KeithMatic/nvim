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

**Theme italics**:
Which kinds of code (comments, keywords, functions, ...) a theme draws in italics, chosen separately
for each theme family from the options that family offers. The line diagnostics and **Breadcrumbs**
are italic whatever the theme, and aren't among them.
_Avoid_: Font style, italic toggles

**Tint**:
The colour faded over the theme's background that marks "where am I" lines: the cursor line, the explorer's line and the selected menu item.
_Avoid_: Cursorline colour, highlight

**Cursor line**:
The line under the cursor in a file's window, marked by the **Tint**; hidden while typing, and
switched off and on as a Toggle. Hidden, it leaves only its **Mode-coloured line number**. Menus
and panels keep their own selected line either way.
_Avoid_: Cursorline (the option), current-line highlight

**Mode colours**:
The theme's colours for normal, insert, visual, command, delete and copy, shared by the **Cursor
line** (which is hidden in insert), the **Mode-coloured line number** and the statusline's mode icon
(which shows a **Layer**'s icon and colour instead while one is active in Normal mode).

**Mode-coloured line number**:
The cursor's line number, drawn in the current mode's **Mode colour**, whether or not the **Cursor
line** shows; on its own it has no **Tint** behind it.
_Avoid_: Modicator (the plugin that inspired it), CursorLineNr

**Line numbers**:
The numbers down the left of a file's window, absolute or relative; shown only in windows holding a
file, never on the **Dashboard**, terminals, help, the **Explorer** or other panels. Switching them off
and on, from anywhere, sets the choice for files and is remembered across sessions. Beside them, no
git or diagnostic icons unless switched on.
_Avoid_: Gutter, number column

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

**Buffer sticks**:
The column of short marks at the right edge, one per open file, marking the current, the alternate
and the unsaved ones in the theme's colours; the only open-files indicator, with no tabs along the top.
Terminals, help and other non-file buffers get no stick.
_Avoid_: Bufferline, tabs

**Buffer list**:
The **Buffer sticks** expanded into names with short labels; typing a label jumps to that file or
closes it, and the file under the selection is previewed in the current window as you move.
_Avoid_: Buffer picker (that's the fuzzy picker), jump list

**Column order**:
The order of the **Buffer sticks**, which previous/next file steps through: **Pinned** files first,
then the rest, newly opened files at the end; files can be moved up and down it. Kept with the session.

**Pinned**:
A file held at the top of the **Column order** and skipped by every bulk close (others, left, right,
unpinned). Closing it by choice closes it and drops the pin. No mark of its own.
_Avoid_: Sticky, locked

**Breadcrumbs**:
The path to the symbol under the cursor, in italics at the top of the window, and echoed in the
statusline in comment colour.
_Avoid_: Winbar, symbol path

**Dashboard**:
The start screen shown when Neovim opens with no file.
_Avoid_: Start page, splash

**Motion hints**:
The keys that reach each spot on the cursor line (w, b, e, ^, $, ...), drawn beneath it; hidden until toggled, for practising motions.
_Avoid_: Precognition (the plugin, not the concept)

**Animations**:
The editor's motion effects: the **Cursor trail**, smooth scrolling and window resizing, switched
off and on together and remembered across sessions; left to the GUI in Neovide.
_Avoid_: Mini Animate (the plugin, not the concept)

**Cursor trail**:
The path the cursor is drawn along when it jumps to a far spot; one of the **Animations**. A
one-line step isn't a jump.
_Avoid_: Smoothcursor, smear

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

**Layer**:
A named set of one-key actions laid over the usual keys until it's left (<esc> or q), when the
keys it covered come back exactly as they were; ? shows its keys, the statusline's mode icon becomes
its icon, and switching to another file leaves it. One at a time, and never remembered across sessions.
_Avoid_: Hydra, submode, mode (Vim's modes are something else)

**Git layer**:
The **Layer** for reviewing hunks (<leader>gH): it starts on the first hunk and shows the git signs
until it's left, whatever they're switched to otherwise.
_Avoid_: Hunk mode, review mode

### Tools

**Database client**:
The one database UI: connections, the Database drawer, and results that page, edit and export. SQL table and column completion in `.sql` files doesn't depend on it.
_Avoid_: DBUI, sqmeow, dadbod (the plugins, not the concept)

**Database drawer**:
The Database client's tree of connections and their schemas, docked on the left; opening it from the Database client's keys puts the cursor in it, and one key (<leader>0) jumps to it and back.
_Avoid_: sqmeow drawer, database explorer, Explorer (that's the file tree)
