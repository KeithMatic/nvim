# mdkite.nvim and kitehost.nvim

Replace LazyVim's `markdown-preview.nvim` with **mdkite.nvim** for the **Markdown preview**, and add
**kitehost.nvim** as the **Live server**. Both are pure Lua (no Node build step) and live in one new
file, `lua/plugins/preview.lua`, under a new `<leader>v` **Browser group**. The Markdown preview stays
on LazyVim's `<leader>cp` too. Both plugins load lazily, when you press a key or run a command, and
neither starts on its own.

## Terms

These follow the glossary in `CONTEXT.md`.

- **Markdown preview**: the current Markdown buffer rendered in a browser tab, updated as you type
  and scrolled with the cursor; one tab, which the newest Neovim to start it takes over (mdkite.nvim).
  _Avoid_: live preview, mdkite, markdown-preview (the plugins, not the concept)
- **Live server**: a local server for a file or folder (HTML, CSS, JS) that reloads the browser on
  save; started only on request (kitehost.nvim).
  _Avoid_: dev server, kitehost, live-server (the plugins, not the concept)
- **Browser group**: the `<leader>v` keys that show things in the browser: the Markdown preview and
  the Live server.
  _Avoid_: kitehost keys, `<leader>l` (that's Lazy)

## Why

selimacerbas renamed their markdown-preview.nvim to mdkite.nvim (github.com/selimacerbas/mdkite.nvim)
and their live-server.nvim to kitehost.nvim (github.com/selimacerbas/kitehost.nvim, v2.0.0). Both
should be set up in this config.

This config never used either of the old selimacerbas plugins. Its Markdown preview was
*iamcco*/markdown-preview.nvim, which LazyVim's markdown extra installs. Replacing that with mdkite
is a swap to a different plugin, not following a rename. Q1 makes that swap on its own merits: pure
Lua with no Node build, plus Mermaid, KaTeX and scroll sync.

## Locked decisions

### markdown-preview.nvim is disabled; mdkite takes over `<leader>cp` (Q1 → A)

The `lang.markdown` extra stays imported (it also brings render-markdown.nvim, marksman and
markdownlint). Only `iamcco/markdown-preview.nvim` is turned off, with `enabled = false`, and
`<leader>cp` (Markdown buffers only) runs `:MdKite toggle`.

- Rejected **B, keep both**: two browser previews would compete for the same habit, and the Node
  build would be kept alive for nothing.
- Rejected **C, drop the markdown extra**: you would lose render-markdown, marksman and lint, and
  have to configure them by hand.
- To roll back, flip `enabled` on markdown-preview.nvim and remove the mdkite spec. Otherwise two
  `<leader>cp` mappings would compete in Markdown buffers.

### `<leader>v` is the Browser group (Q2 → B)

kitehost's README suggests `<leader>l`, but LazyVim uses that for `:Lazy`. `<leader>m` is already
the habit-tips group. `<leader>v` is free here and no LazyVim extra claims it.

- Rejected **A, `<leader>j`**: just as safe, but `j` doesn't stand for anything.
- Rejected **C, one key under `<leader>c`**: the stop and status commands would be forgotten.
- Rejected **D, follow the README and move `:Lazy`**: it fights LazyVim habits for a plugin you
  use far less than `:Lazy`.

## Routine choices

- **Q3 → B**: four Live server commands get keys: start, stop (pick port), stop-all and status.
  open, reload and toggle-live are left to `:KiteHost <Tab>`.
- **Q4 → A**: Mermaid renders with mermaid.js in the browser (`mermaid_renderer = "js"`, the
  default). No mermaid-rs-renderer binary is needed. Revisit if large diagrams lag.
- **Q5 → A**: `instance_mode = "takeover"` (default): one browser tab on port 8421, and the newest
  Neovim to start a preview takes it over.
- **Q6 → A**: the Live server never auto-starts (no `auto_start`). Start it by key or with
  `:KiteHost start`.
- **Q7 → A**: the Markdown preview is reachable from both `<leader>vm` and `<leader>cp`, each
  scoped to Markdown buffers.
- **Q8 → B**: Live server keys are `<leader>vs` start, `<leader>vx` stop, `<leader>vX` stop all and
  `<leader>vi` status (lowercase stops one, uppercase stops all).
- **Q9**: all specs go in a new file, `lua/plugins/preview.lua`.

Resulting keymap:

| Key | Action | Scope |
| --- | --- | --- |
| `<leader>v` | which-key group "browser" | all buffers |
| `<leader>vm` | Toggle Markdown Preview (`:MdKite toggle`) | Markdown buffers |
| `<leader>cp` | Toggle Markdown Preview (`:MdKite toggle`) | Markdown buffers |
| `<leader>vs` | `:KiteHost start` (pick path & port) | all buffers |
| `<leader>vx` | `:KiteHost stop` (pick port) | all buffers |
| `<leader>vX` | `:KiteHost stop-all` | all buffers |
| `<leader>vi` | `:KiteHost status` | all buffers |

## Verified facts

- `config/lazy.lua` imports `lazyvim.plugins.extras.lang.markdown`. Its markdown-preview.nvim spec
  maps `<leader>cp` (ft markdown) to `MarkdownPreviewToggle` and builds through
  `mkdp#util#install`.
- LazyVim maps `<leader>l` to `:Lazy`. This config's which-key spec makes `<leader>m` "habit tips"
  (`lua/plugins/ui.lua`).
- When the grill ran, these leader prefixes had no mappings: i, j, r, t, v.
- telescope.nvim is not installed (only a stale `telescope-fzf-native` lock entry), so kitehost's
  pickers fall back to `vim.ui.select`/`vim.ui.input`, which Snacks styles. The README's telescope
  dependency is dropped.
- mdkite requires kitehost.nvim ≥ 2.0.0 and Neovim ≥ 0.10, and loads its browser libraries
  (markdown-it, KaTeX, Mermaid, highlight.js) from CDNs.
- mdkite defines no keymaps. Its commands are `:MdKite [start|stop|refresh|toggle]`.
- kitehost's commands are `:KiteHost start|stop|stop-all|open|reload|toggle-live|status`. It binds
  to 127.0.0.1 and uses port 8000 by default.

## Risks

- The Markdown preview needs network access to the CDNs on first render. Offline, it falls back to
  whatever the browser has cached.
- Takeover mode uses a fixed port, 8421. Another program on that port blocks the preview.
- Both plugins are young and were just renamed. API or command changes would show up as broken
  keys after `:Lazy update`.

## Deferred

None.

## Open threads

None.
