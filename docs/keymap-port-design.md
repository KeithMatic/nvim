# Keymap port and clash resolution

The old AstroNvim `mappings.lua` (one table keyed by mode, fed to AstroNvim's `set_keymaps`) is ported
into `lua/config/keymaps.lua`. It keeps that table design, but every key is checked against what this
LazyVim config already does. Where a Ported key duplicates an existing key, the existing one wins. Where
it Clashes with a key that has a different meaning, each case is decided below. Keys that depended on
AstroNvim, Telescope or Oil are dropped or pointed at installed tools. The bugs in the half-done port
(undefined helpers, a search key that ends in Visual mode, an `<F2>` that deletes the selection) are fixed.

## Terms

These follow the glossary in `CONTEXT.md`.

- **Ported key**: a key brought over from the old AstroNvim `mappings.lua` into `lua/config/keymaps.lua`.
  _Avoid_: new key, Astro key.
- **Clash**: two definitions of the same key in the same mode, where the one set later silently shadows
  the other. _Avoid_: conflict, collision.
- **Prefix delay**: the `timeoutlen` pause (300 ms in LazyVim) a key gains when it becomes the start of a
  longer mapping: `Y` waits once `YY` exists. _Avoid_: lag, timeout.
- **Menu keys**: the Ctrl-h/j/k/l keys that drive an open completion menu (dismiss, next, previous,
  accept) and move the cursor when none is open.
- **Column order**: the order the **Buffer sticks** are drawn and stepped through with `H` / `L`.

## Why

In the user's words: "implement the new keymap design from the example mappings.lua file and then
review the keymaps as I believe there's a huge clash and I want to resolve it."

What was actually going on:

- `keymaps.lua` called `o(...)` and `opts`, which are never defined, so it errored at the first new line.
  Nothing after it loaded, including the whole `mappings.lua` table pasted below it.
- That table `require`d AstroNvim modules that don't exist here (`nvim.mainm.config.nvim.lua.user.util.macro`,
  `…user.util.map`, `…user.oil`, `astrocore.buffer`, `astroui.status`), plus Telescope and Oil, which
  aren't installed.
- Once those load errors were fixed, several Ported keys would silently shadow keys this config relies on:
  `H`/`L` (the Buffer sticks), insert `<C-h/j/k/l>` (the Menu keys), insert `<M-j>` (LazyVim's
  move-line), `<C-s>`, `<leader>ff`, `<leader>bD`, `n`/`N`, visual `r`, and a global `<CR>` that would
  take Enter away from quickfix.

## Locked decisions

### The existing key wins over a duplicating Ported key (Q2)

When a Ported key does a job this config already does, the Ported copy is dropped. That covers:

- `<C-s>`: LazyVim saves in n/i/x/s.
- `H`/`L`: the Buffer sticks step through the Column order.
- `<leader>ff`: LazyVim's Snacks picker.
- Insert `<C-h/j/k/l>`: the Menu keys already move the cursor, with `<C-g>U`, so undo and dot-repeat
  survive.
- The in-file duplicates of `<C-c>` and `yrw`/`yrW`/`yre`/`yrE`: one copy each.

The same rule settled `<leader>bD` (LazyVim's Delete Buffer and Window stays; the sticks'
`<leader>bx` already picks a file to close), `<leader>bn` (Q12), `<leader>u1` (Q13), and the empty
`<M-h>`/`<M-l>` normal entries (AstroNvim's "unset" idiom, with nothing to unset here).

Rejected:
- **The Ported key wins, rewritten for LazyVim.** `H`/`L` as `:bnext` would ignore Pinned files and
  the Column order. Global insert `<C-h/j/k/l>` would lose the Menu keys' undo-safe moves. This is the
  Clash the user was worried about.
- **Existing wins, except `<C-s>` becomes `:w!`.** Force-writing a read-only file is rare enough to type.

### Oil is not added; `-` opens mini.files at the current file (Q4, Q11)

`-` opens mini.files (the enabled LazyVim extra) on the current file's folder with the file revealed,
the same as `<leader>fm`, falling back to the cwd for an unnamed or unsaved buffer. `<leader>O` is
dropped, since it duplicated `<leader>fm`. Nothing to do with oil.nvim is added.

Rejected:
- **Add oil.nvim** (first chosen, then withdrawn): "Forget oil.nvim as it will mess up everything." It
  would have been a third file UI next to the Explorer and mini.files. Its buffer-local defaults
  (`<C-h>`, `<C-l>`, `<C-s>`, `<C-c>`, `<C-t>`) would also Clash with keys used everywhere else (Q10,
  now deferred).
- **Drop `-` too**: it would leave Neovim's built-in `-` (up a line to the first non-blank), which `k`
  and `+` already cover.

## Routine choices

- **Q1, the file's shape:** one table keyed by mode (`n`, `i`, `x`, `t`) fed to a short local
  `set_keymaps` helper inside `keymaps.lua`. There's no new module, and every `vim.keymap.set` call
  stays in `keymaps.lua`, so the README test attributes keys to the right file.
- **Q14:** all keymaps in the file move into the table, including the ones that were already there:
  `<leader>/`, `gco`/`gcO`, `<leader>cx`, `<C-/>`/`<C-_>`, `<leader>ft`/`<leader>fT` and `<leader>sK`.
  Only `require("statusline").filename_toggle():map("<leader>uN")` and
  `require("persistent_toggles").setup()` stay as calls.
- **Q3:** insert `<M-h>` / `<M-l>` outdent / indent via `<C-d>` / `<C-t>`, so the cursor stays on its
  character. `<M-j>` is not ported, so LazyVim's insert `<M-j>`/`<M-k>` move-line stays.
- **Q5:** normal `<CR>` → `ciw` and `<BS>` → `ci` only in editable file buffers (`buftype == ""` and
  `modifiable`). Anywhere else they act as Neovim's own key, so Enter still jumps in quickfix and runs
  the line in the command-line window.
- **Q6:** `<F2>` and `<F2><F2>` are dropped in every mode ("remove and forget").
- **Q7:** normal `<C-a>` = Select All (`ggVG`), giving up normal-mode increment (visual `g<C-a>` still
  works; `vag` also selects all through mini.ai). Insert `<C-a>` / `<C-e>` = start (first non-blank) /
  end of line. blink.cmp's `<C-e>` hides an open menu first and falls back to this mapping otherwise.
- **Q8:** `n`/`N` keep LazyVim's direction fix (`'Nn'[v:searchforward]`), and centre and unfold
  (`zzzv`). `*`/`#` = `*zzzv`/`#zzzv`, `g*`/`g#` = `g*zz`/`g#zz`. Visual-mode `n`/`N` stay LazyVim's.
- **Q9:** `U` = redo, `YY` = yank the enclosing `{ }` block linewise (`va{Vy`), and `d.` = delete the run
  of spaces under the cursor down to one. All three are ported as written, accepting `Y`'s 300 ms
  Prefix delay.
- **Q12:** `<leader>bn` (New Tab) is not ported; `<leader><Tab><Tab>` already makes a new tab.
- **Q13:** `<leader>u1` (Toggle Aerial) is not ported; `<leader>cs` already toggles it.
- **Q15:** visual `r` = substitute the selection across the whole file, matched literally (`\V\C`, with
  `/`, `\` and newlines escaped), as `:%s/…//g` with the cursor waiting in the replacement, so every
  copy on a line is replaced, not just the first. It's mapped in
  Visual mode only (`x`), not Select mode, so typing `r` over a snippet placeholder still types `r`.
- Also ported as written, with no Clash: `yrw`/`yrW`/`yre`/`yrE` (substitute on the line, from the word),
  `<C-c>` (copy the file to the clipboard), and insert `<M-o>`/`<M-O>` (open a line below/above).
- Every Ported key gets a which-key `desc` that starts with a verb, in Title Case (CODING_STANDARDS.md),
  and a row in the README's keymap tables, which `tests/readme_spec.lua` enforces.

## Verified facts

- `keymaps.lua` as edited errors at its first new line: `o` and `opts` are undefined.
- `nzzv` ends in Visual mode: it's `n`, `zz`, `v`, not `n`, `zz`, `zv`.
- Visual `<F2>` (`'<'>%s/…`) types `'<`, `'>`, `%`, then `s`, which deletes the selection and enters
  Insert mode.
- Normal `<F2>` (`y:%s/…`) is `y` with a `:` command-line motion, not a yank of the line.
- LazyVim maps `<C-s>` (n/i/x/s), `<S-h>`/`<S-l>` (overridden here by the Buffer sticks), `<leader>bD`,
  insert `<A-j>`/`<A-k>` (move line), `n`/`N` (direction-fixed with `zv`), and sets `timeoutlen` to 300.
- `lua/plugins/editing.lua` defines the Menu keys on blink.cmp and removes LazyVim's insert `<C-k>`
  signature help so it can't shadow them.
- Oil, Telescope (except `telescope-fzf-native`, used by dropbar) and AstroNvim are not installed.
  mini.files (extra `editor.mini-files`) and aerial (extra `editor.aerial`) are.
- LazyVim's mini.ai config defines a `g` (whole buffer) text object.
- Nothing in this config or LazyVim maps normal `-`, `<F2>`, `U`, `YY`, `d.` or insert `<M-o>`/`<M-O>`.

## Risks

- The helper sets keys in table order, which Lua doesn't fix for string keys. Nothing here depends on the
  order, because each lhs appears once per mode.
- With `mini.animate` on, every centred search jump plays a short scroll animation.
- A global normal `<CR>` / `<BS>` still applies in an editable buffer with a special purpose, for example
  a plugin's scratch buffer with `buftype == ""` that expects Enter. Such a buffer needs its own
  buffer-local map.
- Visual `r` yanks into register 0 and the yank history, as the Ported key always did.
- Overriding normal `<C-a>` costs counted increments (`5<C-a>`).

## Deferred

- **Q10: Oil's buffer keys versus this config's.** This only matters if oil.nvim is ever added. If it is,
  remap Oil's split/vsplit/tab/refresh away from `<C-h>`, `<C-s>`, `<C-t>` and `<C-l>`, and put refresh
  on `gR` with `nowait`, not `gr`, which would wait for Neovim's `grn`/`grr`/`gri`/`gra`.

## Open threads

None.
