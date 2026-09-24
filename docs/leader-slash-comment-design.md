# Leader slash comment toggle

Use Celeste as this configuration's comment engine, retaining AstroNvim's `<leader>/` aliases for `gcc` in Normal mode and `gc` in Visual mode. Celeste adds cursor tracking, persistent adjusted selections, block comments and the selected advanced operations. Disable ts-comments.nvim, pin Celeste to the reviewed commit, and retain project search on `<leader>sg`.

## Terms

- **Comment toggle**: comment or uncomment the current line or selected text. Avoid: none.
- **Comment engine**: the implementation that resolves syntax and edits text; shortcuts can remain the same when the engine changes. Avoid: none.
- **Sticky cursor**: the cursor follows its original character as comment markers are inserted or removed. Avoid: none.
- **Adjusted selection**: selection endpoints follow the text through comment edits. Avoid: none.

## Why

The user prefers AstroNvim's `<leader>/` shortcut to typing `gcc`, while retaining `gcc` as an option. After implementing those aliases, they asked to compare celeste_comment.nvim with the current setup and adopt its additional capabilities. They selected Celeste as the replacement engine, active adjusted Visual selections, and the wider toolkit using the proposed keys.

## Locked decisions

None. These are reversible configuration choices; no architectural decision record is needed.

## Routine choices

- Carry forward the original interview's search decision: `<leader>/` comments and `<leader>sg` searches the project.
- Replace native commenting plus ts-comments.nvim with Celeste (upgrade Q1, A). Keep `gc`, `gcc`, and `<leader>/` available, now backed by Celeste. A parallel-engine trial would create two behaviors and extra shortcuts; retaining the old engine would omit the selected capabilities.
- Enable `keep_cursor = true` and `keep_selection = "adjust | keep_visual"` (Q2, A). Selected text remains active after commenting, so `<leader>/` immediately toggles it again. Escape returns to Normal mode. Returning to Normal mode automatically, with or without adjusted marks, was not selected.
- Enable the wider toolkit, including insertion helpers, auto-uncomment, force-add/remove, and inversion (Q3, C). A line/block-only setup would leave those requested operations unbound.
- Use the proposed Normal/Visual keys and Alt-/ in Insert mode, also accepting Alt-_ (Q4, A). No separate custom key scheme is needed.
- Pin `celeste3z/celeste_comment.nvim` to `b39441f1bb84a925e57299db78719ed8361b809c`. Upstream allows breaking changes in minor releases. Update the explicit pin and lockfile together after review.
- Configure the engine in `lua/plugins/comments.lua` on `VeryLazy`, after LazyVim's initial keymap setup. Disable `folke/ts-comments.nvim` rather than layering its global commentstring override under a second engine.
- Keep the leader aliases in `lua/config/keymaps.lua` with `remap = true`, so they resolve to Celeste's `gcc`/`gc` mappings.
- Retain buffer-local comment options and all unspecified Celeste defaults. Do not clear `commentstring` or `comments` globally.

### Shortcut reference

Leader is Space. Case matters.

| Mode | Keys | Action |
| --- | --- | --- |
| Normal | `Space /`, `gcc` | Toggle current line; counts apply |
| Visual | `Space /`, `gc` | Toggle selected lines and keep adjusted selection active |
| Normal | `gc{motion}` | Toggle lines covered by a motion |
| Normal | `gbc` | Toggle block comment on current line |
| Normal | `gb{motion}` | Toggle block comment over a motion |
| Visual | `gb` | Toggle block comment over selection |
| Operator-pending | `gc`, `gb` | Line/block comment textobjects, e.g. `dgc` |
| Insert | `Alt-/`, `Alt-_` | Toggle line while preserving Insert-mode editing position |
| Normal | `gco`, `gcO` | Insert a comment line below/above and place the cursor on it |
| Normal | `gcA` | Insert a comment marker at line end and place the cursor there |
| Normal | `gcu` | Detect and uncomment surrounding comment |
| Normal/Visual | `gcI` | Invert comment state per line |
| Normal/Visual | `gCC` | Force-add a comment layer |
| Normal/Visual | `gCU` | Force-remove a comment layer from commented lines |
| Normal | `.` | Repeat the last edit |
| Normal | `Space s g` | Search project contents |

`gcI`, `gCC`, and `gCU` take a motion in Normal mode: `gCC_` acts on the current line. In Visual mode they act directly on the selection. Force-add can add another layer to already-commented lines; invert changes each line independently. Optional auto/inner textobjects remain unmapped.

## Verified facts

### Existing setup

[AstroNvim's mapping source](https://github.com/AstroNvim/AstroNvim/blob/main/lua/astronvim/plugins/_astrocore_mappings.lua) uses remappable `gcc` and `gc` aliases for `<Leader>/`. The earlier change copied those aliases and verified Normal/Visual toggling, counts, dot-repeat, and project-search preservation.

Installed Neovim is v0.12.5. Installed LazyVim loads ts-comments.nvim on VeryLazy. Its local source overrides `vim.filetype.get_option` for commentstring resolution, with Tree-sitter-aware JSX/TSX handling and detection of alternate comment forms. Context awareness and variant detection therefore already existed before Celeste.

### Celeste review

Reviewed [Celeste source at b39441f](https://github.com/celeste3z/celeste_comment.nvim/blob/b39441f1bb84a925e57299db78719ed8361b809c/lua/celeste_comment/init.lua) and [the corresponding documentation](https://github.com/celeste3z/celeste_comment.nvim/blob/b39441f1bb84a925e57299db78719ed8361b809c/doc/celeste_comment.md). That commit is dated 2026-09-22. It supports Neovim 0.12 and includes compatibility paths for 0.12.2+ position APIs.

Celeste supplies its own operators, line/block syntax tables, Tree-sitter resolution and comment textobjects. It models changes as text edits, allowing cursor and selection endpoints to track inserted/removed markers. The reviewed source tracks operator state through ModeChanged; it does not install the dot-repeat mapping described in the older README snapshot. No obsolete `dot_repeat` or `track_state` configuration is added.

A clean Neovim comparison using C buffers confirmed line round trips, counted operations, dot-repeat and Visual line toggling in both engines. Starting on the variable in `int a = 1;`, the old engine moved the cursor to column 0; Celeste tracked it to column 7 after adding `// ` and restored column 4 on removal. Celeste's `gbc` produced `/* int a = 1; */`.

| Capability | Previous setup | Celeste |
| --- | --- | --- |
| Line toggles, counts and repeat | Available | Available |
| Context-aware syntax and comment variants | Provided by native engine plus ts-comments | Built-in resolver and syntax table |
| Dedicated block-comment operators | No equivalent configured | `gb`, `gbc` |
| Cursor follows original text | Not observed in comparison | Verified |
| Adjusted selection stays active | Not configured | Explicitly enabled |
| Force-add/remove and per-line invert | Not configured | Explicitly enabled |
| Insert-mode toggle | Not configured | Explicitly enabled |

## Risks

- Celeste changes the implementation behind `gcc`; this preserves the shortcut, not a separate native fallback.
- Visual mode now remains active after comments; press Escape before Normal-mode commands.
- Alt-key delivery depends on terminal/GUI configuration. Both Alt-/ and Alt-_ are mapped; physical keyboard delivery still needs a user check.
- Contextual syntax depends on the relevant Tree-sitter parsers. Simple filetype syntax remains the fallback.
- Comment textobjects use heuristics and can confuse comment-like tokens inside strings. Lua line/block prefixes are ambiguous for auto-detection; explicit `gc`/`gb` operations are preferable there.
- Visual block selections are commented per line, not per column. Block textobject scans are bounded by the plugin's default search limit.
- Python block comments use triple-quoted strings in the upstream syntax table; these are string literals, not Python comment tokens. Use line comments for ordinary Python commenting.
- Mapping ownership must be checked after full LazyVim startup, particularly `gco` and `gcO`, which LazyVim also defines.

## Deferred

- Custom auto/inner textobject keys: revisit if explicit line/block textobjects are insufficient.
- Plugin upgrades: revisit deliberately when new functionality or a fix is needed; review changes before moving the pin.

## Open threads

None. All four upgrade questions were answered before Finish.
