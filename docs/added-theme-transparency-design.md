# Transparency for Added themes

Added themes (the repos pasted into `added` in `lua/config/themes.lua`) should look like the Theme
families: transparent from the very first frame, with the same groups cleared and the same accents
kept. Today they fail on both counts. Their `Normal` background stays solid until a scheduled
restyle runs, which causes the flash at startup and on every switch or preview. They also leave some
panel and gutter groups solid that Transparency doesn't list. The fix has four parts. Transparency
is applied synchronously inside the ColorScheme hook, after the theme's own background is recorded.
The clear list gains the groups the Added themes leave solid beyond the Baseline. Redraws are held
while `M.detect` reads themes. `tests/transparency_spec.lua` checks every dark Added theme, before
the event loop runs as well as after. There is no visual for this design.

## Terms

These follow the glossary in `CONTEXT.md`.

- **Transparency**: panel and float backgrounds cleared so the terminal's glass shows through,
  whatever the theme, a float's Frame included; also the In-text blocks, which keep only their
  colour. _Avoid_: glass, no-background.
- **Theme family**: Curated themes that share one setup and one set of options this config knows:
  tokyonight (night, storm, moon) and catppuccin (frappe, macchiato, mocha). Other Curated themes
  belong to no family. _Avoid_: colorscheme family, theme pack.
- **Added theme**: a Curated theme from a plugin named in the config rather than built in; only the
  dark themes it ships count. _Avoid_: extra theme, installed theme.
- **Flash**: a redraw showing a theme's solid background before Transparency clears it: at startup,
  or on a switch or preview to the theme. _Avoid_: flicker.
- **Theme read**: converge applying a theme for a moment to record its colours, for the Mix or to
  leave the light Added themes out of the Curated themes; nothing is drawn, saved or restyled
  meanwhile. _Avoid_: capture, probe.
- **Baseline**: what Transparency leaves solid on tokyonight-moon: the accents (folds, the colour
  column, the quickfix line, the wildmenu, the completion scrollbar, float shadows), which every
  theme keeps solid too. _Avoid_: reference theme, default look.

## Why

> I've installed my preferred themes under lua/config/themes.lua but I see a few issues with the
> background on most themes and when I startup neovim, I get a flash of the background of the
> theme. Ensure that all themes are transparent matches the initial design of the whole config.

The config is built for a translucent, blurred WezTerm window (README). Only the Theme families
were ever made transparent at the source. Added themes, introduced with the Mix, rely entirely on
`lua/theme.lua`'s `make_transparent`. It runs inside `vim.schedule(restyle)`, so Neovim draws at
least one frame before it.

## Locked decisions

### 1. Added themes become transparent through a clear in the theme hook (Q1 → A)

In `on_change` (`lua/theme.lua`), after `theme_palette()` has recorded `M.background` and the Mode
colours, and before returning, call `make_transparent()` directly. Keep `vim.schedule(restyle)`
(which runs `make_transparent` again, then the italics) for plugins whose own ColorScheme hooks run
after ours and redefine their highlights (lualine, noice, blink, ...). The `LazyLoad`/`VeryLazy`
restyle stays as it is.

Ordering matters. `palette_of` reads the live groups of the applied theme (`groups_of` when
`name == vim.g.colors_name`), so the palette must be read **before** the clear. Otherwise
`M.background` is lost, and the Tint, Block guide and modes.nvim blend over `#000000`.

`theme.with_background` (used for modes.nvim) still works. Its `solidify_normal` ColorScheme hook
was created after the theme hook, so it runs after the hook's clear. It saves the
already-cleared `Normal`, makes it solid for modes.nvim's hook, and `restore_normal` puts the
cleared version back. No redraw happens inside that chain of autocommands.

Rejected:

- **B: turn on each Added theme's own transparency option from a table of known repos.** It needs
  a table to maintain, and any repo missing from it still flashes. A theme that clears its own
  `Normal` also removes the background that `palette_of` and converge's Mix snapshots read, so each
  repo's palette would need wiring in, as tokyonight's and catppuccin's are.
- **C: both.** It carries B's maintenance and palette costs, and only covers the repos in the
  table. A alone already covers every repo.

Accepted cost: a plugin whose own ColorScheme hook runs after ours and sets a solid panel can still
show for one frame, until the scheduled pass runs. None of the panels in use do this today, and
lualine's theme (`theme.lualine`) is already background-free.

### 2. Theme reads: hold redraws in `M.detect`, accept the Mix's cache-miss frame (Q4 → C)

The hook's clear must not run during a Theme read. converge snapshots a theme's groups after
`:colorscheme`, so clearing then would record a transparent snapshot. The early return on
`require("mix").reading` in `on_change` stays.

- `M.detect` reads every unread Added theme in one synchronous call. Wrap that call (the loop over
  `snapshots.get(..., { capture = true })` and the restore of the current theme) so it can't
  redraw. Stub `vim.cmd.redraw` the same way `theme.with_background` does, and set `'lazyredraw'`
  for the duration. Restore both afterwards, even when an error is raised (pcall, then re-raise).
  This removes the "brief flash" that `lua/config/themes.lua`'s comment currently admits to; update
  that comment.
- On a cache miss for the Mix (for example the first start after editing `mix` in themes.lua),
  converge's `M.apply` (converge.nvim `lua/converge/init.lua:132-155`) schedules the capture for the
  next loop tick and then reruns `:colorscheme converge`. One frame can draw in between. This is
  **accepted**: holding redraws across that tick would mean wrapping or patching converge's own
  code, and the frame shows only once after each Mix edit.

Rejected:

- **A: hold redraws across both kinds of read.** It gives the strongest guarantee, but couples the
  config to converge's internals for a frame seen once per Mix edit.
- **B: accept both.** It would leave a known flash in the picker, which this design sets out to
  remove.

## Routine choices

- **Clear list: parity with the Theme families (Q2 → A).** Extend `transparency.groups` in
  `lua/theme.lua` with the groups the Added themes leave solid beyond the Baseline, and keep the
  Baseline accents solid:
  - Gutter git signs, by exact name: `GitSignsAdd`, `GitSignsChange`, `GitSignsDelete`,
    `GitSignsTopdelete`, `GitSignsChangedelete`, `GitSignsUntracked` (kanagawa, nordic draw blocks
    in the sign column). Not a `GitSigns` prefix: the `…Ln`, `…Inline` and `…Preview` groups are
    diff line highlights, which catppuccin also keeps solid.
  - The completion menu's columns: `PmenuKind`, `PmenuExtra`, `PmenuBorder` (cendre, kanagawa,
    nightfall). `PmenuSbar` stays (Baseline). `PmenuSel` and `PmenuThumb` are already kept by
    `keep`.
  - Inactive windows (onedarkpro): `SignColumnNC`. `FoldedNC` and `QuickFixLineNC` stay solid, to
    match `Folded`/`QuickFixLine` in the Baseline.
  - `NonText` (onedarkpro gives it a background, which shows past the end of the buffer).
  - Noice's LSP progress text: prefix `NoiceLspProgress` (nordic). `NoiceFormatProgressDone` is a
    progress bar, an accent chip, and stays.
  - `SnacksWinBarNC` (`SnacksWinBar` is already listed).
  - `AerialNormal`. `AerialLine`/`AerialLineNC` are "where am I" highlights and stay.
  - `StatusLineTerm`, `StatusLineTermNC` (palenight, palenightfall, oldworld, nightfall).
  - `MsgSeparator` (kanagawa, nightfall).
  - Left solid on purpose: `TroubleCount` (badge), `TroublePreview` ("where am I"), and the
    Baseline accents.
  - Rejected: B, clearing the accents too, which would change the Theme families' look as well; C,
    inverting to a keep-list, which would clear accent chips in every theme.
- **The Theme families keep their own transparency options (Q3 → A).** On top of them the
  hook's clear does nothing, and their options also shade borders and titles for a transparent
  background. `tests/transparency_spec.lua` pins that look.
- **Regression spec (Q5 → A).** Extend `tests/transparency_spec.lua`. Run `M.detect()`, then take
  every dark Added theme from `theme.curated()`, excluding the families and `converge`. For each:
  - right after `vim.cmd.colorscheme(name)`, before yielding to the event loop, assert that `Normal`
    has no background (this is the flash test);
  - after the scheduled restyle (`vim.wait`), assert that the existing `transparent` list and the
    Q2 additions have no background;
  - assert that the Baseline accents are untouched (still solid wherever the theme defined them
    solid);
  - assert that `theme.background` is set (the palette was recorded before the clear).

  Because the loop goes over whatever `added` holds, a newly pasted repo is checked without editing
  the spec. Run it with `tests/run.sh tests/transparency_spec.lua`.
- **themes.lua example (Q6 → A).** In `lua/config/themes.lua:10`, replace
  `opts = { transparent = true }` with a non-transparency option, for example
  `{ "rebelot/kanagawa.nvim", variants = { "kanagawa-dragon" }, opts = { theme = "dragon" } }`.
  Add one line: Transparency is applied to every theme, so leave a theme's own transparency option
  off, because it hides the background the Tint is faded over.

## Verified facts

Established by probing every installed Added theme headlessly, with `XDG_STATE_HOME` isolated so
the saved theme was untouched:

- `Normal` before restyle, per theme: kanagawa `#1f1f28`, kanagawa-dragon `#181616`, nordic
  `#242933`, onedark `#282c34`, nord `#2e3440`, oldworld `#161617`, palenight `#292d3e`,
  palenightfall `#252837`, cendre `#171311`, nightfall `#141423`, evergarden `#232a2e`, the oasis
  family (`#000000` to `#2c1724`). tokyonight-moon and catppuccin-mocha: `NONE`. This confirms the
  flash's cause.
- The saved theme in `~/.local/state/nvim/theme.json` is `kanagawa`, so every start flashes today.
- The solid groups each theme leaves after restyle, filtered to plugins this config uses, are the
  source of the Q2 list. Baseline from tokyonight-moon: `ColorColumn`, `Folded`, `QuickFixLine`,
  `WildMenu`, `PmenuSbar`, `FloatShadow(Through)`, `LspSignatureActiveParameter`, `TroubleCount`,
  plus groups for plugins not in use.
- Groups for plugins that aren't installed (TreesitterContext, Neogit, nvim-notify, DapUI, Mini,
  Navic, barbar's `Buffer*`) are out of scope.
- Light variants (kanagawa-lotus, onelight, evergarden-summer, winter, ...) are already excluded by
  `M.detect`/`M.curated`.
- converge's `M.apply` captures on the next tick on a cache miss (`lua/converge/init.lua:132-155`).
- `tests/transparency_spec.lua` covers only the six Theme families today, and asserts after the
  scheduled restyle. It would pass with the flash present.

## Risks

- **A late ColorScheme hook re-solidifies a panel.** Any plugin whose ColorScheme hook runs after
  ours and sets a solid listed group shows it for one frame until the scheduled pass. Mitigated by
  the scheduled restyle, which stays.
- **Palette read order.** If `make_transparent` ever moves above `theme_palette()` in `on_change`,
  `M.background` silently becomes the `NormalFloat`/`Pmenu` fallback or nil, and the Tint blends
  over black. The spec's `theme.background` assertion guards this.
- **Stubbing `vim.cmd.redraw` in `M.detect`.** It is a global monkeypatch. It must be restored on
  error, and must not nest badly with `with_background`'s stub (they don't overlap in time:
  `with_background` runs at plugin setup, `M.detect` when the picker opens).
- **The Mix's cache-miss frame** remains, by decision.
- **Exact-name additions** don't cover a future repo that solidifies a new group. The spec catches
  only groups it names. A new leftover shows up visually, and is added to the list when it does.

## Found during implementation

Extending the spec to every dark Added theme turned up several more ways an Added theme missed the
initial design. All of them are fixed, with tests:

- **Even the Theme families flashed slightly.** tokyonight left `StatusLine` and `Pmenu` solid, and
  catppuccin left `Pmenu` solid, until the scheduled pass. The hook's clear fixes them too.
  catppuccin's `PmenuKind`/`PmenuBorder` stripes are now cleared, as the Q2 list says.
- **Light themes offered as dark.** kanagawa-lotus and onelight don't set `'background'` to light,
  so converge records them as dark. `is_dark` in `lua/theme.lua` now also rejects a light editor
  background (perceived lightness ≥ 0.5).
- **Themes that don't name themselves.** palenight never sets `g:colors_name`, so its palette
  wasn't read (the Tint was faded over black) and it couldn't be saved. The hook now names the
  theme from the ColorScheme event's `match`.
- **Panels linked to a theme's own sidebar group.** `NeoTreeNormal` links to evergarden's `Panel`
  and nordic's `TreeNormal`, which have backgrounds. A listed group whose link target keeps a
  background now takes the target's colours without the background, as in-text groups already did.
- **Flat statusline modes.** `theme.lualine` restyled lualine's theme tables in place. Themes that
  ship their own lualine theme return the same table every time, and evergarden shares sections
  between modes (`command = normal`). The second pass then set the mode text to `NONE`. It now
  restyles a copy, and each section once.
- `BufferLineBufferSelected` is no longer asserted: bufferline is disabled in this config, and the
  group is kept on purpose (`keep` matches `Sel`).

## Found in the whole-branch review

- **A Baseline accent linked to a group Transparency clears lost its block.** kanagawa's `WildMenu`
  is a link to `Pmenu`. Before clearing, `make_transparent` now gives such an accent its target's
  colours, block included. The per-theme test checks linked accents too, and a fixture theme covers
  it in CI.
- **The redraw hold also catches `vim.cmd("redraw")`.** Holding redraws is now one helper,
  `theme.without_redraws`, shared by the Theme read and `with_background`. An
  `nvim_command("redraw")` still draws: nothing in the API stops it.
- **The Theme read moved to `lua/curated_themes.lua`** with the rest of the Curated themes' code.
  `detect` is now `read_added`, and `M.themes` is now `built_in`.

## Deferred

None.

## Open threads

None.
