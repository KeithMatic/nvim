# Extra italics: design

Extend the Theme italics picker (`<leader>uy`, `lua/theme_italics.lua`) so you can make far more Syntax types italic than a theme offers. Today only tokyonight's 4 options and catppuccin's 12 are available. The new **Extra italics** are an extensive list, chosen once and shared by every theme. They sit in their own section of the same picker, below the theme's own options. The second-font idea (Fira Code for strings) is dropped: Operator Mono SSm Lig stays the only font. The work ships with a beginner-friendly guide, `docs/theme-italics-guide.md`, that walks through the real changes.

## Terms

- **Theme italics**: the existing picker (`<leader>uy`) that switches italics on or off per Syntax type for the current Theme family. Saved in `theme.json`. *Avoid:* italic settings, italics menu.
- **Syntax type**: a kind of code text the editor colours on its own, such as comments, keywords, strings, function names or parameters. *Avoid:* token, scope, capture (in the guide; fine in code comments).
- **Theme family**: a group of themes that share one setup, such as tokyonight (night, storm, moon) or catppuccin (frappe, macchiato, mocha). *Avoid:* colorscheme family, theme pack.
- **Extra italic**: a Syntax type that this config adds to the Theme italics picker. The theme does not offer it, and it is applied after any theme loads. *Avoid:* custom italic, override.
- **Font slot**: one of the four faces a terminal holds at once (regular, italic, bold, bold italic). Neovim can only ask for a style, and the terminal picks the font. Kept only to explain why fonts were dropped. *Avoid:* font face, font variant.

## Why

In the user's words: expand the theme configuration "to support additional syntax types for italics, even if they are not provided by the current theme". The user also wanted multiple fonts per syntax element (Operator Mono for function names and variables, Fira Code for strings). They then dropped that and chose to "use the currently installed font and discard the rest of the questions and guide for different fonts". The final output should let a user with basic editor experience customise italics, with a clear step-by-step guide and little jargon.

## Locked decisions

### 1. Make real changes in this config, and write the guide as a walkthrough of them (Q1 → A)

The guide names real files and shows each change before and after. Its testing section says exactly what you should see.

- *Rejected: guide only, the user makes the edits.* The guide could describe code that doesn't match this config, and it couldn't point at the existing picker.
- *Rejected: a guide for any editor.* It would be mostly generic and couldn't build on Theme italics.

### 2. No second font (Q2 → "drop second font completely", Q4 → drop fonts from the guide entirely)

Neovim runs inside WezTerm, and a terminal draws text in only four Font slots. Fira Code for strings would have meant lending one slot (bold italic was the recommendation) to Fira Code and drawing strings in that style. The user dropped this. Operator Mono SSm Lig stays the only font in WezTerm (and Ghostty). Function names and variables are already in Operator Mono, and italic text uses its cursive italic face automatically. No terminal config changes. The guide has no fonts section and no unapplied recipe.

- *Rejected: lend bold italic to Fira Code.* It works, but the user decided the second font isn't wanted.
- *Rejected: lend bold to Fira Code.* Bold is used widely (headings, statusline, matched brackets), so all of it would switch font.
- *Rejected: switch to Neovide.* It has the same four font slots, so it gains nothing.
- *Rejected (Q4): explain Font slots plus an optional recipe, or pin WezTerm's italic face with `font_rules`.* The user asked to discard the fonts content completely.

### 3. Extra italics are new options in the Theme italics picker, working on every theme (Q3 → A)

The picker is already how italics are chosen, so extras belong there: toggled with `<leader>uy`, saved in `theme.json`, and applied after any theme loads. This follows the pattern `theme.lua`'s `italicise()` already uses for line diagnostics and Breadcrumbs.

- *Rejected: a fixed always-italic list in `theme.lua`.* Changing your mind would mean editing Lua.
- *Rejected: each family's own hook (`on_highlights`, `custom_highlights`).* It duplicates every choice per family and does nothing for other themes.

### 4. Extra italics are chosen once, shared by every theme (Q7 → A)

Italic taste follows the font (Operator Mono's cursive), not the colours. Extras keep their state when you switch theme, and they work on themes Theme italics doesn't know.

- *Rejected: per Theme family.* You would re-pick the same extras on every family. The cost accepted: you can't have parameters italic on tokyonight but upright on catppuccin.

### 5. One picker with two sections; an extra the current family already offers is hidden (Q8 → A)

The theme's own options come first (saved per family, unchanged). Extra italics follow (shared). If the current family offers a Syntax type, its extra row is hidden, so there is never a second "comments" row. On tokyonight, comments, keywords, functions and variables are hidden from the extras. On catppuccin, all twelve of its options are. The extras section is shorter on catppuccin than on tokyonight, which is expected.

- *Rejected: one merged list, one row per Syntax type.* It reads cleanest, but hides which rows follow you across themes, so a theme switch can surprise you.
- *Rejected: everything becomes an Extra italic and theme options are turned off.* It throws away the theme's own italic handling, which often covers plugin highlights the shared list wouldn't. It would also need the saved per-family choices migrated.

## Routine choices

- **The extensive list (Q6):** the curated set (parameters, types, properties, built-ins, decorators, imports, constants, return/exception keywords), plus catppuccin's twelve so tokyonight gets the same list. The user asked for the list to be extensive, so it adds a few more common italic picks (methods, modules, markup tags and attributes, characters and escapes, documentation comments). See the table below.
- **Defaults:** every Extra italic starts off, so nothing changes until one is flipped.
- **Guide location and shape (Q5 → A):** a Markdown file in this repo, `docs/theme-italics-guide.md`, versioned with the code it describes. It opens in Neovim through render-markdown. It has four sections: the user's five, minus Implementing Multiple Fonts.
  1. Reviewing the Current Theme Configuration
  2. Identifying Syntax Types for Expansion
  3. Adding Italics to New Syntax Types
  4. Testing and Validation
- **Design doc path:** this file is `docs/theme-italics-design.md`, not the `docs/theme-italics-and-fonts-guide.md` proposed at the start. Fonts were dropped, and the guide gets its own file.
- **Saving:** `theme.json` (`stdpath("state")`) gains a top-level `extra_italics` map, `{ [option] = boolean }`, beside `theme`, `tint` and the per-family `italics`.
- **Applying:** extras are applied in the same ColorScheme hook as `italicise()` (`theme.lua`'s `restyle()`), after the theme. Each matching highlight is read with `link = false`, `italic = true` is set, the `default` flag is dropped (as `italicise()` already does), and the highlight is written back. Flipping an extra re-applies the theme, as flipping a theme option already does (`reload`). That way, turning an extra **off** restores the theme's own style rather than leaving a stale italic.
- **Picker rendering:** the picker still uses `vim.ui.select` and reopens after each flip. Rows carry a section label (the family name for theme options, "extra" for Extra italics) and the existing check/close icon, with the theme's rows first.

### The Extra italics list (proposed highlight names)

Each option covers the listed highlight names and their language-specific variants (e.g. `@variable.parameter.lua`). It does not cover deeper sub-types that belong to another option: `@function` does not include `@function.builtin` (built-ins) or `@function.method` (methods). The hidden-when-offered column says which family already offers the option.

| Extra italic | Highlight names | Hidden on |
|---|---|---|
| comments | `Comment`, `@comment` | tokyonight, catppuccin |
| documentation comments | `@comment.documentation`, `@string.documentation` | none |
| keywords | `Keyword`, `Statement`, `@keyword`, `@keyword.function` | tokyonight, catppuccin |
| conditionals | `Conditional`, `@keyword.conditional`, `@keyword.conditional.ternary` | catppuccin |
| loops | `Repeat`, `@keyword.repeat` | catppuccin |
| return/exception keywords | `@keyword.return`, `@keyword.exception`, `Exception` | none |
| imports | `Include`, `@keyword.import` | none |
| functions | `Function`, `@function`, `@function.call` | tokyonight, catppuccin |
| methods | `@function.method`, `@function.method.call` | none |
| variables | `Identifier`, `@variable` | tokyonight, catppuccin |
| parameters | `@variable.parameter`, `@variable.parameter.builtin` | none |
| properties | `@property`, `@variable.member` | catppuccin |
| built-ins (self/this) | `@variable.builtin`, `@function.builtin`, `@type.builtin`, `@constant.builtin`, `@module.builtin` | none |
| types | `Type`, `@type`, `@type.definition` | catppuccin |
| constants | `Constant`, `@constant`, `@constant.macro` | none |
| modules | `@module` | none |
| decorators | `@attribute`, `@attribute.builtin` | none |
| strings | `String`, `@string` | catppuccin |
| characters and escapes | `Character`, `@character`, `@string.escape`, `SpecialChar` | none |
| numbers | `Number`, `Float`, `@number`, `@number.float` | catppuccin |
| booleans | `Boolean`, `@boolean` | catppuccin |
| operators | `Operator`, `@operator`, `@keyword.operator` | catppuccin |
| markup tags and attributes | `@tag`, `@tag.attribute` | none |

Confirm the exact names against Neovim 0.12's treesitter captures (`:help treesitter-highlight-groups`) during implementation.

### Testing and validation (what the guide's section 4 covers)

- Put the cursor on a word and run `:Inspect`. It lists the highlight names that colour it, and so which Extra italic would catch it.
- Keep a small sample file per language you use (Lua, plus any others) that contains every Syntax type in the table. Flip each Extra italic on and off in `<leader>uy` and watch the sample.
- Switch theme (tokyonight-moon to catppuccin-mocha and back) and check that extras survive and that hidden rows change as described.
- Restart Neovim and check that the choices persist (`theme.json`).
- To confirm the terminal draws italics at all, run `printf '\e[3mitalic\e[0m\n'` in WezTerm. You should see Operator Mono's cursive face.

## Verified facts

- The editor is Neovim 0.12.5 with LazyVim, running in WezTerm (`TERM_PROGRAM=WezTerm`). Ghostty and Kitty configs also exist.
- WezTerm (`~/.config/wezterm/wezterm.lua`) uses `Operator Mono SSm Lig` at weight 380, with `Symbols Nerd Font Mono` as fallback. Ghostty uses `Operator Mono SSm Lig`. Kitty uses JetBrains Mono.
- Operator Mono SSm (with Lig and Nerd Font variants, including all italics) and Fira Code Nerd Font are installed in `~/Library/Fonts`.
- The curated themes are catppuccin-frappe/macchiato/mocha and tokyonight-night/storm/moon. The default is tokyonight-moon (`lua/theme.lua`).
- `lua/theme_italics.lua` defines per-family options: tokyonight has comments, keywords, functions and variables. catppuccin has comments, conditionals, loops, functions, keywords, strings, variables, numbers, booleans, properties, types and operators. Options are fed into each theme's `styles` through `lua/plugins/ui.lua`.
- The saved state is `stdpath("state")/theme.json`, currently `{"theme":"tokyonight-moon","tint":{…},"italics":{"tokyonight":{"comments":true,"keywords":true,"functions":false,"variables":false}}}`.
- `lua/theme.lua` already italicises groups after every theme change (`italicise()`, by group name or prefix: `WinBar`, `WinBarNC`, `DiagnosticVirtualText*`, `DropBarKind*`).
- tokyonight's `functions` style also applies to `@keyword.function` (`tokyonight/groups/treesitter.lua:43`). Its `keywords` style covers `Keyword` and `@keyword`, and `variables` covers `Identifier` and `@variable`.

## Risks

- **LSP semantic highlights:** language servers paint `@lsp.type.*` groups on top of treesitter. Neovim combines the two, so italic from below should survive. But a theme that defines an `@lsp.type.*` group with its own `italic = false` would cancel it. Test with a language server attached, and add the `@lsp.type.*` twins (e.g. `@lsp.type.parameter`) to an option's list if needed.
- **Linked groups:** many `@…` groups are links in a theme. Writing an italic copy breaks the link, so a later theme tweak to the target won't flow through until the next theme change. This is acceptable because restyle runs on every ColorScheme.
- **Overlap inside a family's own option:** tokyonight's `functions` also italicises `@keyword.function`, so the hidden "functions" extra and the theme's option don't cover exactly the same names. The guide should mention it so the result isn't a surprise.
- **Too much italic:** an extensive list makes it easy to turn on so much that italic stops standing out. The guide should suggest a starting set (comments, parameters, built-ins, decorators).
- **Picker length:** about 20 extras plus up to 12 theme options in one `vim.ui.select` is long. Section labels keep it scannable. If it gets unwieldy, search in the picker (Snacks select supports filtering).

## Deferred

None. Fonts were dropped outright rather than deferred. A request for a different font on a Syntax type would reopen Q2: the Font slot workaround (lend bold italic to the second font) is recorded under Locked decision 2.

## Open threads

None.
