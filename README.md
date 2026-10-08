# nvim

My personal Neovim config, built on [LazyVim](https://www.lazyvim.org). I moved to it from VS Code. It
covers the languages I write, recreates the small VS Code extensions my muscle memory depends on, and
is built for a translucent, blurred WezTerm window: the UI is transparent, and only the "where am I"
indicators (cursor line, selection, completion item) are solid, tinted by mode.

- [Install](#install)
- [Features](#features)
- [Keymaps](#keymaps)
- [VS Code extensions → Neovim](#vs-code-extensions--neovim)
- [Tests](#tests)

## Install

Needs Neovim 0.12+, git, a [Nerd Font](https://www.nerdfonts.com), and a terminal with true colour
(WezTerm with a translucent background is what it's tuned for).

```sh
mv ~/.config/nvim ~/.config/nvim.bak   # keep any config you already have
git clone https://github.com/KeithMatic/nvim ~/.config/nvim
nvim                                   # plugins install at their locked versions
```

### Why LazyVim is still the base

I keep LazyVim as a lazy.nvim dependency because it gives me a curated, maintained set of defaults
that keeps improving through `:Lazy update`, so this repo only has to hold what is personal to me.
Where LazyVim or one of its extras already does something, this config uses it rather than writing its
own. The words used below (Tint, Layer, Buffer sticks, ...) are defined in [CONTEXT.md](CONTEXT.md).

## Features

### Look

- **Curated themes**: tokyonight (night, storm, moon) and catppuccin (frappe, macchiato, mocha), picked
  with live preview (`<leader>uC`). The last one applied comes back at startup.
- **Transparency**: panel and float backgrounds are cleared whatever the theme, so the terminal's
  glass shows through. Diagnostics, inlay hints and Markdown blocks keep only their colour.
- **Tint**: the cursor line, the Explorer's line and the selected menu item get one colour faded over
  the theme's background. Change it with `:Tint <#rrggbb> <fade 0-1>`.
- **Mode colours**: the cursor line, the cursor's line number and the statusline's mode icon follow
  the current mode. The cursor line hides while you type, leaving only the mode-coloured line number.
- **Theme italics** (`<leader>uy`): choose which syntax types are italic. The current theme's own
  options are remembered per theme family; the extra ones (parameters, built-ins, decorators, ...)
  are shared by every theme.
- **Rainbow brackets** and a **Block guide**: brackets coloured by depth, and one dotted line down the
  block the cursor is in, in a faint shade of that block's bracket colour.
- **Reference highlights**: other uses of the word under the cursor are underlined, never boxed.
- **Statusline**: a mode icon, the Breadcrumbs echoed in comment colour, and a filename you can hide
  (`<leader>uN`).
- **Breadcrumbs**: the path to the symbol under the cursor at the top of the window, in italics.
- **Dashboard**: the start screen when Neovim opens with no file.
- **Cheat sheet**: this README in a float over whatever is open, read-only, from anywhere with
  `<leader>sK` (or `k` on the Dashboard). `q` closes it.
- **Animations**: a cursor trail, smooth scrolling and window resizing, switched together
  (`<leader>ua`) and left to the GUI in Neovide.
- **One icon set** for every kind, diagnostic, gutter sign and file status.

### Navigation

- **Buffer sticks**: one short mark per open file down the right edge (current, alternate, unsaved)
  instead of tabs. `<leader>bj` expands them into a **Buffer list** with jump labels and a live preview.
- **Column order**: `H`/`L` step through files in an order you control. Pinned files come first, you
  can move files up and down, and the order is kept with the session.
- **Pinned files** (`<leader>bp`) survive every bulk close.
- **Explorer**: neo-tree with a single Files tab, floating in the centre by default. `<leader>o` reveals
  the current file. Its Git view is `<leader>ge`.
- **Harpoon**: up to nine marked files on `<leader>1` to `<leader>9`.
- **Flash**: `s` jumps anywhere on screen with labels, and `S` selects a Treesitter node.
- **Layers**: one-key action sets laid over the usual keys until you leave with `q` or `<Esc>`. `?`
  shows their keys, and the statusline icon changes. The **Git layer** (`<leader>gH`) reviews hunks
  one key at a time.
- **Motion hints** (`<leader>uP`): the keys that reach each spot on the line (`w`, `b`, `e`, `^`, `$`,
  ...), drawn under it for practice.
- **Habit tips**: after you do something the long way, a small float shows the better command. Quieten
  them with `<leader>ut`; the Tip guide, Progress and Stats panels are under `<leader>m`.

### Editing

- **Smart semicolon**: in C-like languages, typing `;` mid-line puts it at the end of the code.
  Typing `;` again straight away moves it back to where the cursor was.
- **Tabout**: `<Tab>` moves past a closing bracket or quote. It's part of the completion menu's
  `<Tab>` chain.
- **Menu keys**: `<C-h>`/`<C-j>`/`<C-k>`/`<C-l>` dismiss, move through and accept the completion menu,
  and move the cursor when no menu is open. The same keys walk the command-line history and the
  Database drawer.
- **Better escape**: `jj` or `jk` leave insert mode and the command line, with no typing delay.
- **Smart strings**: typing `{` inside a Python string makes it an f-string, and `${` inside a JS/TS
  quoted string makes it a template literal.
- **Comments**: `<leader>/` toggles a comment; `gc`/`gb` (line and block) work by motion; `<M-/>`
  toggles one in insert mode.
- **Surround** (`gsa`, `gsd`, `gsr`, ...), **yank history** (`<leader>p`, `[y`/`]y`), **colour
  swatches** for `#rrggbb` and Tailwind classes, and **autosave** for real files.

### Tools

- **Terminal manager** (`<C-/>`): a float of named terminals beside a **Terminal list** (`a` add,
  `e` rename, `d` delete, a number switches). `q`/`<Esc>` hide it with every shell still running, and
  `<Esc><Esc>` leaves terminal mode. `<leader>ft`/`<leader>fT` add a terminal at the project root or
  at the current file's folder.
- **Runner** (`<leader>cx`, `:RunFile`): saves the file and runs it in a reused bottom terminal.
  Supports Python, Go, JavaScript, TypeScript (Deno), Lua, Rust (Cargo-aware), C and C++.
- **Database client** (`<leader>D`): connections, the Database drawer (`<leader>0` jumps to it and
  back), and query results that page, edit and export. Table and column completion in `.sql` files.
- **Markdown preview** (`<leader>vm`, or `<leader>cp`): the current Markdown file in a browser tab,
  updated as you type, with Mermaid and KaTeX.
- **Live server** (`<leader>vs`): a local server for a file or folder that reloads the browser on save.
- **Git**: gitsigns, lazygit/GitUI (`<leader>gg`), Snacks git pickers, and GitHub PRs, issues and
  reviews in the editor (`<leader>G`).
- **AI**: Claude Code in a split (`<leader>ac`), with diffs to accept or deny.
- **Debugger** (`<leader>d`): nvim-dap with adapters for every language below.
- **Symbols and rename**: an outline (`<leader>ko`, `<leader>cs`) and a rename preview (`<leader>kr`).

### Languages

TypeScript/JavaScript, Python, Go, Rust, C/C++, HTML, CSS, Tailwind, Emmet, JSON, YAML, TOML, Docker
and Compose, SQL (Postgres, linted and formatted with sqlfluff), Markdown and MDX. Formatting goes
through Prettier and linting through ESLint where they apply.

## Keymaps

`<leader>` is `Space`. Keys marked ★ are added or changed by this config; the rest are
LazyVim's, its extras' or Neovim's own. `<leader>sK` opens this list inside Neovim, `<leader>?`
shows the keys for the current buffer, `<leader>sk` searches them all, and which-key pops up after
any prefix.

### Everyday

| Key | Action |
| --- | --- |
| `<leader>sK` ★ | Cheat sheet: this README in a float |
| `<leader><Space>` | Find files (root dir) |
| `<leader>/` ★ | Toggle comment (line, or the selection) |
| `<leader>,` | Buffers |
| `<leader>:` | Command history |
| `<leader>.` / `<leader>S` | Scratch buffer / select scratch buffer |
| `<leader>e` / `<leader>E` | Explorer (root dir / cwd) |
| `<leader>o` ★ | Explorer, revealing the current file |
| `<leader>;` ★ | Pick a Breadcrumb |
| `<leader>0` ★ | Database drawer, and back |
| `<leader>1`–`<leader>9` | Harpoon to file 1–9 |
| `<leader>H` / `<leader>h` | Harpoon this file / Harpoon menu |
| `<leader>p` | Yank history |
| `<leader>n` | Notification history |
| `<leader>l` / `<leader>L` | Lazy / LazyVim changelog |
| `<leader>-` / `<leader>\|` | Split below / right |
| `` <leader>` `` | Switch to the other buffer |
| `<C-/>` ★ | Terminal manager (normal and terminal mode) |
| `<C-s>` | Save (normal, insert, visual) |
| `<C-h/j/k/l>` | Move between windows |
| `<C-Up/Down/Left/Right>` | Resize the window |
| `<M-j>` / `<M-k>` | Move the line or selection down / up |
| `<Esc>` | Escape and clear the search highlight |
| `s` / `S` | Flash jump / Flash Treesitter select |
| `<C-Space>` | Treesitter incremental selection |
| `H` / `L` ★ | Previous / next file in the Column order |

### Dashboard

| Key | Action |
| --- | --- |
| `f` / `g` / `r` | Find a file / find text / recent files |
| `n` / `c` / `p` | New file / config files / projects |
| `s` | Restore the session |
| `x` / `l` | Lazy extras / Lazy |
| `k` ★ | Keymaps & Features: the cheat sheet (this README) |
| `q` | Quit |

### Files and buffers: `<leader>b`, `<leader>f`

| Key | Action |
| --- | --- |
| `<leader>bj` ★ | Buffer list: jump to a file by label |
| `<leader>bx` ★ | Close a file by label |
| `<leader>bv` / `<leader>bs` ★ | Open a file by label in a vertical / horizontal split |
| `<leader>bp` ★ | Pin or unpin the current file |
| `<leader>bP` ★ | Close every unpinned file |
| `<leader>bo` ★ | Close every other file |
| `<leader>bl` / `<leader>br` ★ | Close the files above / below in the Column order |
| `<leader>bd` / `<leader>bD` | Delete the buffer / the buffer and its window |
| `<leader>bi` | Delete invisible buffers |
| `<leader>bb` | Switch to the other buffer |
| `[b` / `]b` ★ | Previous / next file |
| `[B` / `]B` ★ | Move the file up / down the Column order |
| `<leader>ff` / `<leader>fF` | Find files (root dir / cwd) |
| `<leader>fg` | Find git files |
| `<leader>fr` / `<leader>fR` | Recent files (all / cwd) |
| `<leader>fb` / `<leader>fB` | Buffers (current / all) |
| `<leader>fc` | Find a config file |
| `<leader>fp` | Projects |
| `<leader>fn` | New file |
| `<leader>fe` / `<leader>fE` | Explorer (root dir / cwd) |
| `<leader>fm` / `<leader>fM` | mini.files (file's folder / cwd) |
| `<leader>ft` ★ | New terminal at the project root, in the Terminal manager |
| `<leader>fT` ★ | New terminal at the current file's folder, in the Terminal manager |

### Search: `<leader>s`

| Key | Action |
| --- | --- |
| `<leader>sg` / `<leader>sG` | Grep (root dir / cwd) |
| `<leader>sw` / `<leader>sW` | Word under cursor or selection (root dir / cwd) |
| `<leader>sb` / `<leader>sB` | Lines in this buffer / grep open buffers |
| `<leader>sr` | Search and replace (grug-far) |
| `<leader>sR` | Resume the last search |
| `<leader>sd` / `<leader>sD` | Diagnostics (all / buffer) |
| `<leader>sh` / `<leader>sM` | Help pages / man pages |
| `<leader>sk` | Keymaps (search them all) |
| `<leader>sK` ★ | Cheat sheet: this README in a float |
| `<leader>sC` / `<leader>sc` | Commands / command history |
| `<leader>s/` | Search history |
| `<leader>s"` | Registers |
| `<leader>sm` / `<leader>sj` | Marks / jumps |
| `<leader>sq` / `<leader>sl` | Quickfix / location list |
| `<leader>sa` | Autocmds |
| `<leader>sH` | Highlights |
| `<leader>si` | Icons |
| `<leader>sp` | Search for a plugin spec |
| `<leader>su` | Undotree |
| `<leader>st` / `<leader>sT` | Todos / Todo, Fix, Fixme |
| `<leader>sna` / `snh` / `snl` / `snd` | Noice: all / history / last message / dismiss all |

### Code and LSP: `<leader>c`, `<leader>k`, `g`

| Key | Action |
| --- | --- |
| `<leader>cx` ★ | Run the file (the Runner) |
| `<leader>cf` | Format (file or selection) |
| `<leader>cF` | Format injected languages |
| `<leader>cd` | Line diagnostics |
| `<leader>cs` | Symbols outline (Aerial) |
| `<leader>cS` | LSP references and definitions (Trouble) |
| `<leader>cm` | Mason |
| `<leader>cp` ★ | Markdown preview (Markdown files) |
| `<leader>kr` ★ | Rename with a preview (Lspsaga) |
| `<leader>ko` ★ | Outline (Lspsaga) |
| `<leader>kb` ★ | Toggle the Breadcrumbs |
| `gd` / `gr` / `gI` / `gy` / `gD` | Definition / references / implementation / type definition / declaration |
| `K` | Hover |
| `gra` / `grn` / `grr` / `gri` / `grt` | Code action / rename / references / implementation / type definition |
| `gO` | Document symbols |
| `[d` / `]d`, `[e` / `]e`, `[w` / `]w` | Previous / next diagnostic, error, warning |
| `[[` / `]]` | Previous / next reference to the word |
| `[;` / `];` ★ | Breadcrumbs: start of the context / next context |
| `[i` / `]i` | Top / bottom edge of the scope |
| `[t` / `]t` | Previous / next todo comment |
| `[q` / `]q` | Previous / next Trouble or quickfix item |

### Editing

| Key | Action |
| --- | --- |
| `jj` / `jk` ★ | Leave insert mode or the command line |
| `;` ★ | Smart semicolon (insert, C-like languages) |
| `<Tab>` ★ | Tab out of a bracket or quote (insert) |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` ★ | Menu keys: dismiss / next / previous / accept (insert, command line) |
| `<M-/>` | Toggle a line comment (insert) |
| `gc` / `gcc` | Line comment by motion / current line |
| `gb` / `gbc` | Block comment by motion / current line |
| `gco` / `gcO` ★ | Add a comment below / above |
| `gcA` | Add a comment at the end of the line |
| `gcu` / `gcI` | Uncomment / invert comments |
| `gsa` / `gsd` / `gsr` | Add / delete / replace a surrounding |
| `gsf` / `gsF` / `gsh` | Find right / left surrounding, highlight it |
| `p` / `P`, `[y` / `]y` | Put, then cycle through the yank history |
| `[p` / `]p`, `>p` / `<p`, `=p` | Put linewise, indented, or through a filter |
| `[<Space>` / `]<Space>` | Add an empty line above / below |

### Git and GitHub: `<leader>g`, `<leader>G`

| Key | Action |
| --- | --- |
| `<leader>gg` / `<leader>gG` | GitUI (root dir / cwd) |
| `<leader>gH` ★ | Git layer (see [Layers](#layers)) |
| `<leader>ge` | Explorer's Git view |
| `<leader>gs` / `<leader>gS` | Git status / stash |
| `<leader>gd` / `<leader>gD` | Diff (hunks / against origin) |
| `<leader>gL` | Git log (cwd) |
| `<leader>gb` | Blame the line |
| `<leader>gB` / `<leader>gY` | Open / copy the line's URL on the forge |
| `<leader>gi` / `<leader>gI` | GitHub issues (open / all) |
| `<leader>gp` / `<leader>gP` | GitHub pull requests (open / all) |
| `<leader>Gpo` / `Gpd` / `Gpr` | Open a pull request / its details / refresh |
| `<leader>Grb` / `Grs` / `Grd` | Begin / submit / delete a review |
| `<leader>Gtc` / `Gtn` / `Gtt` | Create a thread / next thread / toggle threads |
| `<leader>Gio` / `Gip` | Open / preview an issue |
| `<leader>Gco` / `Gcp` | Open / pop out a commit |
| `<leader>Glt` | Toggle the litee panel |

### Terminal manager

| Key | Where | Action |
| --- | --- | --- |
| `<C-/>` ★ | anywhere | Show or Hide the Terminal manager |
| `<Esc><Esc>` ★ | terminal mode | Leave terminal mode (one `<Esc>` still reaches the shell) |
| `q` / `<Esc>` ★ | normal mode | Hide (every terminal keeps running) |
| `<C-h>` | terminal | Go to the Terminal list |
| `<C-j>` / `<C-k>` | terminal | Next / previous terminal |
| `<C-l>` | Terminal list | Back to the terminal |
| `a` / `e` / `d` | Terminal list | Add / rename / delete a terminal |
| `1`–`9` | Terminal list | Switch to that terminal |

### Database: `<leader>D`

| Key | Action |
| --- | --- |
| `<leader>Dd` ★ | Toggle the Database client |
| `<leader>0` ★ | Jump to the Database drawer and back |
| `<leader>Da` ★ | Add a connection |
| `<leader>Ds` ★ | New scratchpad |
| `<leader>Dc` ★ | Cancel the running query |
| `<leader>Dr` ★ | Run the statement (or the selection) — SQL files |
| `<leader>De` ★ | Run the whole file — SQL files |
| `<leader>Db` ★ | Switch the buffer's database — SQL files |
| `?` | Show the drawer's and results' keys (inside them) |

### Browser: `<leader>v`

| Key | Action |
| --- | --- |
| `<leader>vm` ★ | Toggle the Markdown preview (Markdown files) |
| `<leader>vs` ★ | Start the Live server |
| `<leader>vx` / `<leader>vX` ★ | Stop the Live server / stop all of them |
| `<leader>vi` ★ | Live server status |

### AI: `<leader>a`

| Key | Action |
| --- | --- |
| `<leader>ac` | Toggle Claude Code |
| `<leader>af` | Focus Claude |
| `<leader>ar` / `<leader>aC` | Resume / continue a conversation |
| `<leader>ab` | Add the current buffer |
| `<leader>as` | Send the selection (visual) |
| `<leader>aa` / `<leader>ad` | Accept / deny a proposed diff |

### Debug: `<leader>d`

| Key | Action |
| --- | --- |
| `<leader>db` / `<leader>dB` | Toggle a breakpoint / conditional breakpoint |
| `<leader>dc` / `<leader>da` | Run or continue / run with arguments |
| `<leader>dC` / `<leader>dg` | Run to the cursor / go to the line without running |
| `<leader>di` / `<leader>do` / `<leader>dO` | Step into / out / over |
| `<leader>dj` / `<leader>dk` | Down / up the stack |
| `<leader>dl` | Run the last configuration |
| `<leader>dP` / `<leader>dt` | Pause / terminate |
| `<leader>dr` / `<leader>ds` | Toggle the REPL / session |
| `<leader>du` / `<leader>dw` / `<leader>de` | DAP UI / widgets / evaluate |
| `<leader>dpp` / `dph` / `dps` | Profiler: toggle / highlights / scratch buffer |

### Diagnostics and lists: `<leader>x`

| Key | Action |
| --- | --- |
| `<leader>xx` / `<leader>xX` | Diagnostics (all / buffer), in Trouble |
| `<leader>xq` / `<leader>xQ` | Quickfix list / in Trouble |
| `<leader>xl` / `<leader>xL` | Location list / in Trouble |
| `<leader>xt` / `<leader>xT` | Todos / Todo, Fix, Fixme, in Trouble |

### Toggles and look: `<leader>u`

Every toggle is remembered across sessions except the temporary modes (zen, zoom, dimming and the
profiler), which always start off. `:ToggleStateReset` puts them all back to their defaults.

| Key | Action |
| --- | --- |
| `<leader>uC` ★ | Pick a curated theme, with live preview |
| `<leader>uy` ★ | Theme italics |
| `<leader>uH` ★ | Cursor line |
| `<leader>ul` / `<leader>uL` ★ | Line numbers / relative numbers (files only) |
| `<leader>uG` ★ | Git signs beside the line numbers |
| `<leader>ug` ★ | Block guide |
| `<leader>uN` ★ | Statusline filename |
| `<leader>uP` ★ | Motion hints |
| `<leader>ut` ★ | Habit tips |
| `<leader>ua` | Animations |
| `<leader>uS` | Smooth scroll |
| `<leader>uz` / `<leader>uZ` | Zen mode / zoom (`<leader>wm` too) |
| `<leader>ud` / `<leader>uh` | Diagnostics / inlay hints |
| `<leader>uf` / `<leader>uF` | Format on save (global / buffer) |
| `<leader>us` / `<leader>uw` / `<leader>uc` | Spelling / wrap / conceal |
| `<leader>uT` / `<leader>uD` / `<leader>ub` | Treesitter highlight / dimming / dark background |
| `<leader>uA` / `<leader>up` | Tabline / auto pairs |
| `<leader>ui` / `<leader>uI` | Inspect the highlight / the Treesitter tree |
| `<leader>un` / `<leader>ur` | Dismiss notifications / redraw and clear |

### Habit tips: `<leader>m`

| Key | Action |
| --- | --- |
| `<leader>mm` ★ | Show the next tip now |
| `<leader>mg` ★ | Tip guide |
| `<leader>mp` ★ | Progress |
| `<leader>ms` ★ | Stats |
| `x` (in a tip) | Mute that tip |

### Windows, tabs and sessions

| Key | Action |
| --- | --- |
| `<leader>wd` / `<leader>wm` | Close the window / zoom it |
| `<C-w><Space>` | Window "hydra" mode (which-key) |
| `<leader><Tab><Tab>` / `<leader><Tab>d` | New / close tab |
| `<leader><Tab>[` / `<leader><Tab>]` | Previous / next tab |
| `<leader><Tab>f` / `<leader><Tab>l` / `<leader><Tab>o` | First / last tab / close other tabs |
| `<leader>qs` / `<leader>ql` / `<leader>qS` | Restore the session / the last one / pick one |
| `<leader>qd` | Don't save this session |
| `<leader>qq` | Quit all |

### Layers

A Layer lays one-key actions over the usual keys until you leave it. `?` lists its keys, and `q` or
`<Esc>` leaves it. Switching to another file leaves it too.

**Git layer** (`<leader>gH` ★):

| Key | Action |
| --- | --- |
| `n` / `j` | Next hunk |
| `p` / `k` | Previous hunk |
| `s` / `r` | Stage / reset the hunk (the selected lines in visual mode) |
| `u` | Undo the last stage |
| `S` / `R` | Stage / reset the whole file |
| `v` | Preview the hunk inline |
| `b` | Blame the line |
| `d` | Diff the file |
| `w` | Word diff |

### Commands

| Command | Action |
| --- | --- |
| `:RunFile` ★ | Save and run the current file (the Runner) |
| `:Tint <#rrggbb> <fade 0-1>` ★ | Set the Tint colour and how strongly it shows |
| `:ToggleStateReset` ★ | Restore every remembered toggle to its default |
| `:Tobira`, `:TobiraGuide`, `:TobiraProgress`, `:TobiraStats` | Habit tips and their panels |
| `:MdKite toggle` | Markdown preview |
| `:KiteHost start\|stop\|stop-all\|status` | Live server |
| `:Sqmeow ...` | Database client |
| `:FloatermToggle` | Terminal manager |

## VS Code extensions → Neovim

| VS Code extension | Neovim equivalent |
| --- | --- |
| Smart Semicolon | Own `semicolon` module: `;` goes to the end of the line in C-like filetypes, `;;` gives a literal |
| TabOut (taboutx) | Own `tabout` module, called from the blink.cmp `<Tab>` chain |
| f-string converter | nvim-puppeteer |
| Backticks (template literals) | nvim-puppeteer |
| Code Runner | Own `runner` module: `<leader>cx` / `:RunFile` in a reused bottom terminal |
| Integrated terminal | Own `terminal` module on floaterm: `<C-/>` |
| Colorize | `util.mini-hipatterns` extra |
| Path Intellisense | blink.cmp path source (LazyVim default) |
| Emmet (built in) | emmet-language-server |
| Tailwind CSS IntelliSense | `lang.tailwind` extra |
| Prettier | `formatting.prettier` extra |
| ESLint | `linting.eslint` extra |
| MDX | mdx-analyzer (`mdx` filetype) |
| Markdown Preview Enhanced | mdkite.nvim (`<leader>vm`) |
| Live Server | kitehost.nvim (`<leader>vs`) |
| SQLTools | sqmeow.nvim (`<leader>D`) |

## Layout

```
init.lua                 bootstraps lazy.nvim
lua/config/              LazyVim's options, keymaps, autocmds and the extras list (lazy.lua)
lua/plugins/             plugin specs, one file per area (ui, editing, explorer, database, ...)
lua/*.lua                this config's own modules (theme, runner, terminal, semicolon, ...)
lua/layer/               the Layers
tests/                   headless specs, one per feature
docs/                    design docs and ADRs
CONTEXT.md               the glossary: what each feature is called, and what not to call it
```

## Tests

```sh
tests/run.sh                      # every tests/*_spec.lua
tests/run.sh tests/boot_spec.lua  # one spec
```

Each spec boots the real config headlessly inside an isolated XDG sandbox in `.tests/` (separate
config, data, state and cache), so a test run never touches my real Neovim state, saved theme or
plugins. The first run, and any run after `lazy-lock.json` changes, installs plugins at their locked
versions plus LazyVim's Mason tools and Treesitter parsers into the sandbox.

## Roadmap

- **html-end-tag-labels:** Treesitter virtual-text labels after closing HTML/JSX tags.
