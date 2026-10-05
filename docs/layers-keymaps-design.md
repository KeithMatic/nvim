# layers.nvim keymaps: the Git layer

Add [debugloop/layers.nvim](https://github.com/debugloop/layers.nvim) to the config and build the first **layer**: the **Git layer**, for reviewing hunks. You enter it with `<leader>gH` and it turns hunk work into single-key taps (`n`/`j` next, `s` stage, `r` reset, ...). While it's active it shows the gutter signs, puts a themed `git.Branch` icon in the statusline, and toggles a themed help float with `?`. You leave with `<esc>` or `q`, or by leaving the buffer. Shared behaviour lives in a small `lua/layer.lua` factory (not `layers.lua`: layers.nvim already owns `require("layers")`), so the debug and window layers that follow are one small file each.

## Terms

- **Layer**: a `Layers.mode` instance; a named set of keys that temporarily overlays your normal keymaps until you leave it, then restores exactly what was there.
  _Avoid_: hydra, submode, mode (Vim's modes are something else)
- **Overlay**: a `Layers.map` instance; a lighter, modeless set of temporary mappings with no help window or hooks.
  _Avoid_: layer
- **Exit key**: a key that deactivates the current layer and restores the overlaid keymaps.
  _Avoid_: escape hatch
- **Layer convention**: what every layer gets for free from the factory: entry key, `<esc>`/`q` exit, `?` help toggle, statusline icon and colour, and per-buffer scope by default.
  _Avoid_: boilerplate, template

## Why

"I like this debugloop/layers.nvim plugin and I want to incorporate it in my config and make my keymaps easier and more fun." Hunk review today is a chain of chords (`]h`, `<leader>ghs`, `]h`, `<leader>ghs`, ...). A layer turns that into a rhythm of single keys.

## Locked decisions

### Layer code lives in a `lua/layer.lua` factory plus one file per layer (Q9)

`lua/layer.lua` creates layers and applies the layer convention: exit keys, the `?` help toggle, the statusline hook, per-buffer auto-exit, and an "active layer" query. `lua/layer/git.lua` holds only the git layer's keys and its hooks (signs, first-hunk jump). The statusline asks `require("layer").active()` instead of reading globals.

- Rejected **B, inline in each plugin's spec (README style, globals such as `DEBUG_MODE`)**: it lazy-loads with gitsigns for free, but it spreads the convention across plugin specs and leaks globals.
- Rejected **C, one `lua/layer.lua` with every layer**: fine for one layer, but too long by the third.

### Layers are per-buffer by default (Q12)

layers.nvim keymaps are global and it has no buffer-local option. A layer therefore registers a `BufLeave` autocmd on entry that deactivates it; reviewing another file means pressing `<leader>gH` again. The factory takes scope as an option (`scope = "buffer" | "global"`, default `"buffer"`). The debug layer will probably want `"global"`, since stepping jumps across files.

- Rejected **A, global**: suits multi-file review, but layered `n`/`s`/`r` would break neo-tree's and the picker's keys.
- Rejected **C, global but suspended in floats and non-file buffers**: hardest to get right, given that a picker float takes focus.

## Routine choices

- **First layer (Q1)**: git hunk layer (A). Debug was the plugin's showcase but gets used rarely; building all three at once would mean learning three keysets before any had stuck.
- **Help (Q2)**: help window off by default, toggled with `?` inside the layer (C). Not auto-shown on entry (it covers code once you know the keys); some help, rather than none.
- **Active indicator (Q3)**: the statusline's mode icon becomes the layer's icon and colour (A). No modes.nvim cursorline tint, which would fight modes.nvim on every real mode change.
- **Entry (Q4)**: a new key, `<leader>gH` (B). LazyVim's `<leader>gh` hunk group and `]h`/`[h` stay untouched; the layer never starts by itself.
- **Exit (Q5)**: `<esc>` and `q` (B). Not a toggle on the entry key. While the layer is active, `<esc>` overlays LazyVim's `:noh` mapping, and `q` is unavailable for macro recording.
- **Signs (Q6)**: entering shows gitsigns' gutter signs via `require("gitsigns").toggle_signs(true)`, and exit restores the saved choice (A). The persisted `ui.git_signs` toggle (`<leader>uG`, `lua/persistent_toggles.lua`) is never written.
- **Keys (Q7, Q10)**: mnemonic letters plus j/k:

  | Key | Mode | Action |
  | --- | --- | --- |
  | `n` / `j` | n | next hunk |
  | `p` / `k` | n | previous hunk |
  | `s` | n | stage hunk |
  | `s` | x | stage selected lines |
  | `u` | n | undo stage hunk |
  | `r` | n | reset hunk (also `x`: reset selected lines) |
  | `S` / `R` | n | stage / reset whole buffer |
  | `v` | n | preview hunk inline |
  | `b` | n | blame line |
  | `d` | n | diff this |
  | `w` | n | toggle word diff |
  | `?` | n | toggle help window |
  | `<esc>` / `q` | n | exit layer |

  j/k are layered in **normal mode only**. In visual mode they still move lines, so `V j j s` stages part of a hunk (Q10 A).
- **No hunks (Q11)**: `<leader>gH` in a buffer gitsigns doesn't track shows a short notify and doesn't enter. In a tracked buffer it enters, and if the cursor isn't on a hunk it jumps to the first one (C). A clean tracked file still enters, so `b`/`d` stay useful.
- **Statusline look (Q8)**: `git.Branch` icon from `lua/util/icons.lua`, coloured with the theme's `GitSignsChange` foreground, read live from the highlight group so it follows every theme and the glass background. The user's note: "ensure that it follows the theme and it's very elegant and nice". The filename keeps the colour rules it already has; only the mode icon changes.
- **Help window look (Q13)**: the window's `winhl` maps `Normal` to `NormalFloat` (and its border and title to `FloatBorder`/`FloatTitle`) instead of the plugin's `LayersHelpWindow`; set the window title to the layer's icon and name (e.g. ` Git`); keep the bottom-right anchor and the rounded border (A). It matches `winborder = "rounded"` and how which-key, hover and blink look.
- **Roadmap (Q14)**: ship the git layer now; open GitHub issues on `KeithMatic/nvim` for a debug layer and a window layer to grill later (A). Hold off on these until the user confirms opening them.

## Verified facts

- layers.nvim installs as `{ "debugloop/layers.nvim", opts = {} }`; `setup` exposes the global `Layers` table (`Layers.mode.new()`, `:keymaps({ n = {...}, x = {...} })`, `:activate()`, `:deactivate()`, `:toggle()`, `:add_hook(fn)`, `:toggle_help()`, `:auto_show_help()`, and a one-shot activate that exits after one key). `Layers.mode.new()` takes a `name`, which also titles the help window.
- Mappings are restored with Neovim's maparg/mapset, so the overlaid LazyVim mappings (flash's `s`, `:noh` on `<esc>`) come back exactly.
- Help-window defaults: `relative = "editor"`, `width = 24`, `anchor = "SE"`, `style = "minimal"`, `title = "Overlaid Maps"`, `border = "rounded"`, `winhl = "Normal:LayersHelpWindow"`. These are configurable globally in `Layers.config.mode.window`.
- gitsigns is installed with `signcolumn = false` (`lua/plugins/ui.lua:215`); signs are a persisted toggle on `<leader>uG` (`lua/persistent_toggles.lua`, `git_signs()`).
- nvim-dap, dap-ui, dap-virtual-text, dap-go and dap-python are installed (via language extras), so the debug layer needs no new plugin.
- `lua/statusline.lua` draws an icon-only mode section coloured through `theme.mode_color()`; `lua/util/icons.lua` has `git.Branch` and `git.Diff`.
- `persistent_toggles.lua` states that temporary modes always start off. A layer is never persisted across sessions.

## Risks

- **Forgotten layer**: with the help hidden, the statusline icon is the only cue. Mitigated by per-buffer scope (leaving the buffer exits).
- **`<esc>` overlay**: while the layer is active, `<esc>` exits instead of clearing search highlights; `:noh` is lost only during review.
- **`j`/`k` in normal mode**: you can't step one line down inside the layer; use `V`, the arrow keys or `<C-d>`.
- **Lazy loading**: the factory needs `Layers` before `<leader>gH` runs. Make layers.nvim a dependency of the gitsigns spec, or load it on `VeryLazy`. The statusline must handle `Layers` being absent (layer inactive).
- **Auto-exit edge cases**: `BufLeave` also fires when `v` (preview) or `b` (blame) opens a float and focus moves into it. Only exit when the new current buffer is a different file buffer, or ignore floating windows.
- **LazyVim drift**: `<leader>gH` is free today; a future LazyVim release could claim it.

## Deferred

None. The debug and window layers are out of scope by decision (Q14), not deferred; they come back as GitHub issues.

## Open threads

None.
