# Transparent float borders, titles and icons, and the statusline from startup

Some float borders and their contents still show a background: noice's cmdline popup on kanagawa
and nordic's search icon. A float's
**Frame** (border, title, footer, prompt icon) will never keep a background on any Curated theme.
A Frame group that links to a solid group loses that background, and the gutter's diagnostic signs
are cleared. Plugins that load after the startup theme (**Late plugins**) get the whole restyle
when they load, so a fresh start looks exactly like a theme change. A **Float sweep** test opens
every float the config shows on every Curated theme. A startup comparison per theme checks that a
fresh start matches a theme change.

## Terms

**Frame**: A float's border, title, footer and the icon in its prompt (noice's cmdline icon): what
surrounds a float's text.
_Avoid_: chrome, decoration, border items

**Late plugin**: A plugin loaded after the startup theme is applied, so it defines its highlight
groups after Transparency ran. Examples: lualine and noice at VeryLazy, Snacks' notifier on the
first notification, blink on the first insert, neo-tree on first use.
_Avoid_: lazy plugin, deferred plugin

**Float sweep**: A test that opens every float the config shows, on every Curated theme. It checks
that nothing the float draws has a background, except the accents that keep one.
_Avoid_: float audit, popup test

Existing terms used here, from `CONTEXT.md`: **Transparency**, **Curated themes**, **Added theme**,
**Baseline**, **Tint**, **In-text blocks**, **Theme italics** / **Extra italics**.

## Why

The user's words: "I still get backgrounds on border items like noice for commandline and
notifications. Ensure that this is removed and do a thorough work and tests without any issues."

A probe of every Curated theme found three things. It covered the six built-in themes and the dark
themes of the 11 added repos. It opened noice's cmdline popup and Snacks' notifications, both after
a theme change and from a fresh start.

- **Cmdline popup on kanagawa (wave, dragon, lotus excluded as light):** the border, title and icon
  are solid (`#2a2a37` / `#282727`). noice's defaults link `NoiceCmdlinePopupBorder*`,
  `NoiceCmdlinePopupTitle*` and `NoiceCmdlineIcon*` to `DiagnosticSignInfo` / `DiagnosticSignWarn`.
  kanagawa gives the gutter's signs the SignColumn colour as a background. Transparency keeps links
  unless they're panel backgrounds ("Normal" names) or In-text blocks, so the solid background comes
  through the link.
- **nordic:** `NoiceCmdlineIconSearch` is solid.
- **At startup:** the probe read the statusline as solid on several themes, nord among them, until a
  theme was applied again. That turned out to be an artifact of reading screen cells (see Found
  during implementation): no statusline group has a background at startup.
- **Snacks' notifications:** no group they draw with had a background in the probe, at startup or
  after a change. Which notifications the user sees is unknown (Q1), so the Float sweep covers all
  of them.

## Locked decisions

### Q2: Nothing in a float's Frame keeps a background

The border, title, footer and prompt icon all show only their colour.

- **Rejected B:** borders clear, titles keep a coloured block (a "tab" look). A solid title would be
  the one solid patch on a clear float, which is the reported problem.
- **Rejected C:** borders and titles clear, prompt icons keep a chip. The same objection applies:
  noice's cmdline icon was part of the report.
- **Trade-off accepted:** themes that style titles as solid tabs (oasis, nightfall's picker titles)
  lose that look, and a title stands out by colour alone.

### Q3: Late plugins get the restyle when they load (lazy.nvim's `LazyLoad` event)

The restyle runs after every plugin load, and lualine is refreshed then.

- **Rejected B, one more restyle after VeryLazy:** this misses everything loaded later: the notifier
  on the first notification, blink on the first insert, neo-tree on first use.
- **Rejected C, fixing lualine alone:** this fixes only the visible symptom. Every other Late plugin
  stays exposed.
- **Trade-off accepted:** one restyle pass (a walk over all highlight groups, a few ms) per plugin
  load, mostly during startup.

### Q5: Frame links are broken and the gutter's diagnostic signs are cleared

Both fixes apply:

- For a Frame group among the cleared groups (a name containing `Border`, `Title`, `Footer`, `Icon`
  or `Prompt`), break its link when the target has a background. This rule sits beside the existing
  "Normal" panel rule in `make_transparent`.
- Clear `DiagnosticSign*`, the gutter's diagnostic signs. The gutter is transparent, and GitSigns'
  signs were already cleared.

Rejected:

- **B, Frame link-breaking only:** kanagawa's gutter would keep solid sign blocks beside a clear
  SignColumn.
- **C, clearing `DiagnosticSign*` only:** this fixes today's kanagawa case by accident. A theme that
  links a border to `Pmenu`, or that gives an icon its own background, stays solid. Nordic's search
  icon isn't a sign at all.

**Guard:** links outside the Frame names keep their accent (NeoTreePreview → Search, dropbar's
context → Visual, blink's active parameter). The Keep list (`Sel`, `Visual`, `Search`, …) still
applies. The risk is a plugin naming an accent `…Title` or `…Icon`; the Float sweep and the existing
"accents linked to a solid group keep their background" test guard that.

### Q6: A fresh start is compared with a theme change, for every Curated theme

For each Curated theme, the test boots a fresh Neovim with that theme saved and loads every plugin.
It compares every highlight group, and the drawn statusline, with the same theme applied after
everything had loaded.

- **Rejected B, a sample of themes:** the startup bug varied per theme (nord the whole bar, cendre
  two cells), and the report came from nord.
- **Rejected C, the Float sweep in a fresh start per theme:** this doubles the slowest spec. The
  comparison proves the invariant (a fresh start == a theme change), so the in-process sweep's
  result carries over.
- **Trade-off accepted:** about 4 more minutes in the full suite (about 5 s per boot, 44 themes).

**Changed when the spec was written:** the user chose to test at the boot seam only. The Float
sweep and the comparison now both run inside one fresh Neovim per Curated theme: it starts with the
theme saved, sweeps the floats (loading Late plugins as a user would), loads every plugin, then
compares its highlight table with the same theme applied again. This replaces the in-process sweep
and costs more suite time than the estimate above.

### Q8: The restyle after a plugin load is the whole look, and the comparison checks every attribute

The restyle runs the whole scheduled pass: Transparency, the Tint, the italics, the Extra italics
and lualine. The startup comparison checks every attribute, not only backgrounds.

- **Rejected B, Transparency only, comparing backgrounds:** this leaves the same class of startup bug
  for colour and style. The Explorer's cursor line would have no Tint, or the breadcrumbs no
  italics, until the next theme change.
- **Risk:** a plugin that sets a group differently at load on purpose would fail the comparison and
  needs a named exception.

## Routine choices

- **Q1, which notifications:** not known, so the Float sweep covers every float (D).
- **Q4, what the Float sweep opens (A):** every float the config shows, which is:
  - the cmdline popup in each format (`:`, `/`, `?`, `:!`, `:lua`, `:help`, `input()`);
  - noice's confirm and message popups;
  - Snacks' notifications at each level, and their history;
  - LSP progress, hover and signature help;
  - which-key, Lazy and Mason;
  - the picker and input, and blink's menu and docs;
  - the Explorer float, the Terminal manager and the Buffer list;
  - the Habit tips float, the cheat sheet and the Runner.

  For each float, the check resolves everything the window draws with: what its `winhighlight` maps
  `Normal`, `NormalFloat`, `FloatBorder`, `FloatTitle` and `FloatFooter` to, plus every highlight
  its text and virtual text use. Anything with a background fails, except the Q7 accents.
- **Q7, accents inside a float that keep their background (A):**
  - the selected item (the Tint);
  - the scrollbar thumb, the cursor and search matches;
  - noice's confirm buttons (`NoiceFormatConfirm*`) and progress bar (`NoiceFormatProgressDone/Todo`);
  - the picker's window labels (`SnacksPickerPickWin`).

## Verified facts

- noice's defaults (`noice/config/highlights.lua`): `CmdlineIcon = "DiagnosticSignInfo"`,
  `CmdlinePopupBorder = "DiagnosticSignInfo"`, `CmdlinePopupTitle = "DiagnosticSignInfo"`, and
  `…Search = "DiagnosticSignWarn"`.
- `make_transparent` (`lua/theme.lua`) breaks a link only for panel groups whose name contains
  "Normal" and whose target has a background, and for In-text blocks.
- `nvim__inspect_cell` can't be trusted for what's drawn: it reads floats' grids with no attributes,
  and a cell drawn before a highlight was defined decodes through whatever group its attribute
  number stands for now. lualine defines highlights while it draws, so the statusline's cells read
  back as unrelated groups (barbar's `BufferCurrentIndex`). Checks resolve highlights instead: the
  statusline through `nvim_eval_statusline`, floats through their `winhighlight` and extmarks.
- The lualine theme is the function `require("theme").lualine`, which lualine calls on setup and on
  each theme change.
- neo-tree defines its groups only once first used (`require("neo-tree").ensure_config()`). Snacks'
  notifier loads on the first notification.

## Risks

- A plugin that names an accent `…Title`, `…Icon` or `…Prompt` and links it to a solid group loses
  that accent. Example: a selected-tab title linked to `TabLineSel`.
- The Float sweep's openers depend on plugin APIs (noice, Snacks, blink, lspsaga), and may break
  when a plugin updates.
- Restyling on every `LazyLoad` costs startup time; measure it, and coalesce bursts into one pass
  per tick if it's noticeable.
- The startup comparison may flag groups a plugin sets on purpose at load time; each gets a named
  exception.
- The suite gets about 4+ minutes slower.

## Deferred

None.

## Open threads

- Which notifications the user saw with a background is unconfirmed. If the Float sweep finds
  nothing for Snacks' notifications on any theme, ask for the theme and a screenshot.

## Found during implementation

- **The startup statusline was a probe artifact.** The cells the probe read as solid decode through
  unrelated groups (see Verified facts). Evaluated with `nvim_eval_statusline`, the statusline draws
  with no background on every Curated theme at startup. Restyling on each plugin load already
  existed (`LazyLoad`, `VeryLazy`). It now runs once per tick instead of once per plugin (about 70
  at startup). Applying the Tint there turned out unneeded: Late plugins link to the tinted groups.
- **Theme variants were saved as their family.** kanagawa-dragon names itself `kanagawa`, and
  evergarden-spring and -winter name themselves `evergarden`. The config saved and restored
  `colors_name`, so picking kanagawa-dragon came back as kanagawa (wave) on the next start or theme
  change. The theme hook now names a theme as chosen when its colours name it after its family. It
  doesn't rename the Mix, which names itself a tick later. A default like `oasis` stays the variant
  it is (`oasis-moonlight`).
- **What the startup comparison leaves out:**
  - groups only one side defines (plugins that define theirs on first use, or don't define them
    again after a theme change);
  - the `default` flag;
  - the cursors, which modes.nvim colours per mode;
  - which-key's icons, linked to mini.icons' colours only as which-key loads.
