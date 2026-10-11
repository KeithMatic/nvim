# The Mix and added themes: design

Bring in [converge.nvim](https://github.com/SunnyTamang/converge.nvim) to offer a **Mix**: one Curated theme with the
editor's UI from one theme and the code's colours from another. Alongside it, any theme can become a Curated theme by
pasting its plugin repo into one list. Both live in one file you edit, `lua/config/themes.lua`.

## Terms

These follow the glossary in `CONTEXT.md`.

- **Curated themes**: the dark themes the theme picker offers: some built in, any others added by naming their plugin
  (every dark theme it ships), and the **Mix**; the last one applied is restored at startup. *Avoid:* colorschemes (for
  the curated list), theme list.
- **Theme family**: Curated themes that share one setup and one set of options this config knows: tokyonight (night,
  storm, moon) and catppuccin (frappe, macchiato, mocha). Other Curated themes belong to no family. *Avoid:* colorscheme
  family, theme pack.
- **Mix**: a Curated theme made from two others: the editor's UI from one, the code's colours from another, as the
  config names them. Offered in the theme picker beside the rest. *Avoid:* converge (the plugin, not the concept),
  blend, hybrid, recipe.
- **Mode colours**, **Tint**, **Rainbow brackets**, **Block guide**, **Transparency**, **Theme italics**, **Extra
  italics**: as in the glossary.

## Why

In the user's words: "I've just discovered this converge.nvim plugin for themes and I want to incorporate it", wanting
"UI from one Curated theme, syntax from another", and then "the ability to add new themes by just pasting the theme's
plugin repo", remembering "that converge.nvim has a recipe option that allows for overrides, ui and syntax".

## What converge.nvim does, and where it met this config

converge reads each theme once with a real `:colorscheme`, records every highlight group, caches that copy (refreshed
when the theme's files change), and applies a mix of them as one colorscheme named `converge`. Slices: `ui`, `syntax`,
`diagnostics`, `git`, `terminal`, `plugins`; overrides take single groups `from` another theme or `set` them.

Before this change, `lua/theme.lua` found a theme's palette from its name (`^tokyonight%-`, `^catppuccin%-`), and
`lua/theme_italics.lua` found the family the same way. Under converge the name is `converge`, so the Mode colours,
Rainbow brackets and italics family all fell through; the fallback background read `Normal`, which the themes' own
transparency leaves empty, so the Tint blended over black. converge's cache also ignores theme options, so a Theme
italics change replayed stale colours.

## Locked decisions

### 1. converge is a dependency, locked, never vendored

Pinned in `lazy-lock.json`. It has no licence, so its code is not copied in. *Rejected:* waiting; writing our own
mixer (kept as the fallback if converge breaks).

### 2. One Mix, written in `lua/config/themes.lua`, and one picker

`mix = { ui = "tokyonight-moon", syntax = "catppuccin-mocha", overrides = { from = {}, set = {} } }`, shaped like
converge's `recipe`. `diagnostics`, `git`, `terminal` and `plugins` follow the UI theme. The Mix is one entry in the
Curated themes picker (`<leader>uC`), shown by its pair and override count, e.g. `tokyonight-moon + catppuccin-mocha ·
2 overrides`, and applies `converge`. The theme saved in `theme.json` stays the only saved choice.

`:Converge` is deleted when converge loads, and its saved recipe with it, because a recipe saved from its picker would
win over the config. *Rejected:* `:Converge` beside the Curated picker (a second saved choice); replacing the Curated
themes with recipes; several named Mixes (converge holds one recipe).

### 3. Which theme the config's own colours come from

On a Mix: the background (which the Tint, the Block guide and modes.nvim fade over) and the Mode colours from the UI
theme; the Rainbow brackets and the Block guide from the syntax theme. A theme in a Theme family uses its palette; any
other theme is read from its own highlight groups: the background from `Normal` (else `NormalFloat`, else `Pmenu`), and

| Mode colour / bracket | Group |
|---|---|
| insert | `String` |
| visual | `Keyword` |
| delete | `DiagnosticError` |
| copy | `DiagnosticWarn` |
| normal | `Function` |
| command | `Constant` |
| brackets | `DiagnosticWarn`, `Keyword`, `Function` |

A missing group leaves modes.nvim's own colour. The groups are read from the theme as it loads, before Transparency
clears them; a theme that isn't the one applied (the Mix's halves) is read from converge's copy of it.

### 4. Theme italics on a Mix

`<leader>uy` offers the syntax theme's family options (or only the Extra italics, when it has no family). Any change to
a family's options drops converge's copies of that family's themes, so the Mix is read again with them.

### 5. Overrides: only on the Mix, and the config's look wins

An override on something the config sets (the Tint, Transparency, Mode colours, Rainbow brackets, Block guide,
Reference highlights, the always-italic groups) is replaced by it, and reported in a warning at startup. A tweaked
single theme is a Mix of that theme with itself. *Rejected:* overrides winning over the config's look (the same colour
set in two places); overrides on any Curated theme (two override systems).

### 6. Added themes: paste a repo

`added = { "rebelot/kanagawa.nvim" }`. An entry is a repo, or a table `{ "repo", variants = { ... }, opts = { ... } }`
(`opts` goes to the theme's `setup()` through lazy.nvim; `variants` narrows its themes; `dir` instead of a repo names a
local plugin). Each becomes a lazy-loaded plugin. Every theme it ships is a Curated theme, except light ones: the first
time the picker opens after adding one, each new theme is read once (a brief flash) and the light ones are dropped. The
reads are kept in converge's cache, so they happen again only when the theme's files change. *Rejected:* a `:ThemeAdd`
command; guessing light themes by name.

A Mix can use any Curated theme. One whose syntax theme has no family offers only the Extra italics.

### 7. A Mix naming something that isn't a Curated theme

A warning at startup names it. A bad UI theme falls back to the default theme, a bad syntax theme to the UI theme. A
test fails when the configured Mix names anything that isn't a Curated theme, or overrides a group the config sets.

### 8. converge's reads are never your theme

While converge reads a theme (for the Mix, or to find light ones), the theme hook ignores it: nothing is saved, tinted
or restyled.

### 9. The default theme stays `tokyonight-moon`

It's what a fresh start falls back to, and it depends on the fewest things.

## Testing

`tests/mix_spec.lua`, through the same headless sandbox: the Mix's UI and syntax groups match their themes; its
background and Mode colours come from the UI theme and its brackets from the syntax theme; it's listed by its pair and
restored at the next start; reading themes saves nothing; Theme italics on a Mix rebuild it with the syntax theme's
family; the configured Mix is valid; bad names and overrides on config-owned groups are reported. A fixture plugin with
one dark and one light theme checks that only the dark one is offered, that a theme with no family takes its Mode
colours and brackets from its own groups, and that a second check reads nothing.
