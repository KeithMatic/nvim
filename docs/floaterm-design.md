# Floating terminal manager (nvzone/floaterm)

Add **nvzone/floaterm** (with its UI library **nvzone/volt**) as the one home for interactive
shells: the **Terminal manager**, a centred float holding several named terminals beside a
**Terminal list**. `<C-/>` toggles it, replacing LazyVim's Snacks terminal on that key, and
`<leader>ft` / `<leader>fT` add a terminal at the project root / the current file's folder. It is
styled like every other float (NormalFloat over the glass, rounded borders), sized 85% x 80%, and
`q` / `<Esc>` in normal mode **Hide** it without losing any terminal. The **Runner** is unchanged
and keeps its own bottom split.

## Terms

**Terminal manager**: The floating window holding several named terminals plus a sidebar to
switch, add and rename them.
_Avoid_: floaterm (for the concept), terminal pane

**Terminal list**: The sidebar inside the Terminal manager listing each terminal by name.
_Avoid_: tabs, drawer

**Hide**: Closing the Terminal manager's windows while every terminal keeps running, to be shown
again as it was.
_Avoid_: close (which in volt discards the terminals), minimise

All three are in `CONTEXT.md`, under Tools.

## Why

"I want to implement this: https://github.com/nvzone/floaterm": a toggleable floating window
managing several terminal buffers, with a sidebar to switch, add and rename them.

## Locked decisions

### Use nvzone/floaterm itself, not a Snacks rebuild (Q1 → A)

Install `nvzone/floaterm` with `dependencies = "nvzone/volt"`, configured through `opts`, loaded on
`cmd = "FloatermToggle"` and on the keys below.

- **B, rebuild the same on Snacks.terminal + Snacks.win**, lost: floaterm's value is the sidebar
  UI volt draws; re-creating it is a few hundred lines owned forever. (It would have got Snacks'
  theming for free, which A has to bend into shape; see Q4.)
- **C, Snacks float with a picker instead of a sidebar**, lost: not what was asked for; no
  persistent list of named terminals.

This goes against the usual preference for LazyVim extras/core, deliberately: LazyVim ships no
floaterm extra.

### `<C-/>` toggles the Terminal manager; LazyVim's terminal keys are replaced (Q2 → A)

`<C-/>` and its `<C-_>` twin, in normal and terminal mode, toggle the Terminal manager
(`require("floaterm").toggle()`). LazyVim's definitions (`lazyvim/config/keymaps.lua:193-196`)
are overridden. `<leader>ft` / `<leader>fT` are reassigned (Q7).

- **B, keep `<C-/>` as the quick Snacks split, Terminal manager on its own key**, lost: two places
  for shells to live.
- **C, both `<C-/>` and a leader key open the manager**, lost: subsumed by A plus Q7.

Cost accepted: no docked split terminal for side-by-side work (the Runner still has one).

### `q` and `<Esc>` in normal mode Hide, never discard (Q5 → A)

volt maps normal-mode `q` and `<Esc>` in all three floaterm buffers (Terminal list, bar, terminal)
to its own close, whose `after_close` sets `state.terminals = nil`. The list is forgotten and the
shell jobs are orphaned; the next open starts fresh shells. Only `floaterm.toggle()` truly Hides.

Override both keys, buffer-local in normal mode, to call `require("floaterm").toggle()`. They must
be set *after* volt's mappings. Trap: every time a new terminal is first shown, `utils.switch_buf`
calls `volt.mappings` again for **all three** buffers (that terminal, `state.sidebuf`,
`state.barbuf`), re-installing volt's `q`/`<Esc>` on the Terminal list. So the `mappings.term(buf)`
hook, which runs right after that call, must re-apply the overrides to `buf`, `state.sidebuf` and
`state.barbuf`, not just its own buffer.

- **B, `q` hides and `<Esc>` does nothing** (the recommendation), lost: the user wants `<Esc>` to
  be a way out too.
- **C, keep volt's behaviour**, lost: one stray key kills a running dev server.

Consequence: there is no "close everything" key. A terminal is removed with `d` in the Terminal
list or by exiting its shell. Neovim's own TermClose handler only deletes a terminal started as
exactly `$SHELL`, so `lua/terminal.lua` adds one for every Terminal manager terminal (exit status
0, as Neovim's): deleting the buffer closes its window, and floaterm's WinClosed handler takes it
out of the list and shows the next one.

## Routine choices

- **Runner stays as it is (Q3 → A).** `lua/runner.lua` keeps its non-interactive Snacks bottom
  split. floaterm's `api.send_cmd({ name, cmd })` could feed a "Run" terminal, but it types into an
  interactive shell (no stop-previous-run, no fresh output) and the float would cover the code.
- **Look under Transparency (Q4 → A).** Set `border = true`. `lua/terminal.lua` wraps
  `floaterm.open` and `floaterm.utils.set_termwin_hl` (which also runs whenever floaterm makes the
  terminal window again) to set the terminal and bar windows' winhighlight to
  `Normal:NormalFloat,FloatBorder:FloatBorder` and all three windows' borders to `"rounded"`. The
  Terminal list draws through floaterm's own highlight namespace, which wins over winhighlight, so
  `Normal` and `FloatBorder` are copied from the global NormalFloat and FloatBorder into that
  namespace on every open. volt's `Ex*` groups are **not** overridden: with `border = true`, the
  only `Ex*` groups floaterm still draws are foreground-only (ExGreen and ExRed text in the list and
  bar), so the black-slab problem only exists in the borderless look.
- **Starting terminals (Q6 → A).** `terminals` is a function returning one terminal named after
  the project folder (`vim.fs.basename(vim.fn.getcwd())`). The name is fixed at first open; a
  later `:cd` leaves it stale.
- **`<leader>ft` / `<leader>fT` (Q7 → A).** `<leader>ft` adds a terminal at the project root
  (`LazyVim.root()`), `<leader>fT` adds one at the current file's folder. Both use
  `require("floaterm.api").new_term({ name = <folder name>, cmd = "cd " .. shellescape(dir) })`
  (opening the manager first if it is hidden). If floaterm has no terminals yet, the new one
  becomes the starting set instead, so the first use doesn't start the project's shell as well
  (floaterm's own `send_cmd` has that flaw). This works because
  floaterm runs `shell -c '<cmd>; shell'`. `new_term` is not documented as public API.
- **Leaving terminal mode (Q8 → A).** A quick `<Esc><Esc>` in terminal mode goes to normal mode
  (the Snacks convention); a single `<Esc>` still reaches the shell. A buffer-local expression
  mapping set in `mappings.term`: an `<Esc>` within 200 ms of one sent to the shell becomes
  `<C-\><C-n>`. It compares `vim.uv.hrtime()` stamps rather than using a libuv timer as Snacks
  does, since a one-shot timer can still read as active after its time is up until the event loop
  turns. better-escape is left untouched in terminal mode (lazygit keeps `jj`).
- **Size (Q9 → B).** `size = { w = 85, h = 80 }` (percent of the editor), centred; the Terminal
  list keeps floaterm's fixed 20 columns.

## Implementation

- `lua/terminal.lua`: `toggle()`, `shown()`, `new_at(dir)`, the floaterm `opts`, and `setup(opts)` (the
  restyling wraps).
- `lua/plugins/terminal.lua`: the floaterm and volt specs; floaterm loads on first use.
- `lua/config/keymaps.lua`: `<C-/>`, `<C-_>`, `<leader>ft`, `<leader>fT`, set after LazyVim's.
- `tests/terminal_spec.lua`: the behaviour above, end to end.

## Verified facts

From reading floaterm (last commit 2025-09-23, "feat(api): send_cmd()") and volt source:

- Defaults: `border = false`, `autoinsert = true`, `size = { h = 60, w = 70 }`,
  `position = nil`, `mappings = { sidebar = nil, term = nil }`,
  `terminals = { { name = "Terminal" } }` (a table or a function).
- Terminal list keys: `a` add, `e` rename, `d` delete, number keys switch, `<C-l>` to the terminal.
  Terminal keys (`n`, `t`): `<C-h>` to the Terminal list, `<C-j>` next, `<C-k>` previous. These
  agree with the **Menu keys** convention, so they are kept.
- volt maps `<C-t>` (cycle floaterm windows), `q` and `<Esc>` in normal mode on all three buffers.
- The sidebar window's `border = "single"` and the borderless bar/terminal borders are hard-coded
  in `floaterm/init.lua`; there's no option for rounded borders.
- volt's highlights come from `vim.g.base46_cache` (NvChad) or, otherwise, from `Normal`'s bg via
  `nvim_get_hl`. A nil bg becomes `#000000`.
- A `WinClosed` autocmd deletes a terminal from the list when its window closes while the manager
  is shown, so closing the terminal window directly (e.g. `<C-w>q`) deletes that terminal.
- LazyVim's terminal keys start in `LazyVim.root()`; floaterm starts in Neovim's cwd.
- Neovim adds `StatusLine:StatusLineTerm,StatusLineNC:StatusLineTermNC` to a terminal window's
  winhighlight after ours.
- In Neovim 0.12, `nvim_get_hl(ns, { link = false })` on a non-global namespace returns an empty
  table; read namespace highlights without `link = false`.

## Risks

- **Reaching into internals.** Rounded borders, the winhl relink and `<leader>ft/fT` all depend on
  `floaterm.state` fields and `floaterm.api.new_term`, neither documented. An upstream refactor
  breaks them silently. Pin the plugin commit in lazy-lock and recheck on update.
- **`<Esc>` in normal mode Hides.** A nervous triple `<Esc>` from terminal mode lands in normal
  mode and then Hides the manager. Harmless (terminals survive), but surprising.
- **`<C-w>q` deletes a terminal** via floaterm's `WinClosed` handler. Not addressed here.
- **floaterm's `WinClosed` handler is scheduled**, and checks only whether the manager is shown
  when it runs. Hiding and showing it again before the event loop turns (a mapping doing both, or
  a test whose `vim.wait` returns at once) deletes the terminals whose windows were closed.
- **`<C-t>` is taken by volt** in floaterm buffers; any shell binding on `<C-t>` (fzf's file
  widget) only works in terminal mode, which is where it's used anyway.
- **Colours set at open.** The Terminal list's namespace copies NormalFloat/FloatBorder when the
  manager opens, so a theme switched while it's shown only reaches the list on the next open.

## Deferred

None.

## Open threads

None.
