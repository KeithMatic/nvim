# Dropbar and persistent toggles design

Replace Lspsaga's Breadcrumbs with Dropbar while retaining Lspsaga rename and outline. Dropbar will show its full path-and-symbol source chain, support mouse interaction and fuzzy filtering through `telescope-fzf-native.nvim`, and use the config's existing Menu keys. A dedicated toggle-state module will restore the last state of every currently installed toggle, with explicit exceptions for temporary modes. The implementation will not replace `vim.ui.select`.

## Terms

### Breadcrumbs

The winbar path from the current file through the symbol under the cursor; Dropbar will own it after this change.

Avoid: `symbol_in_winbar`, “winbar symbols”.

### Menu keys

`Ctrl-h/j/k/l` dismiss, move to the next item, move to the previous item, and accept the current item whenever an interactive menu is open.

Avoid: “hjkl navigation”.

### Persistent toggle

A toggle whose last chosen value is restored on the next Neovim start.

Avoid: “permanent toggle”.

### Selection provider

The UI used whenever Neovim or a plugin calls `vim.ui.select`.

Avoid: “picker backend”.

## Why

The current Lspsaga setup uses its winbar integration for Breadcrumbs and contains custom redraw and buffer-entry logic so Breadcrumbs can be hidden with `<leader>kb` and brought back in buffers that attached to an LSP while they were hidden. It also uses Lspsaga for rename and outline. Dropbar is more useful for Breadcrumbs because it makes each path or symbol component interactive, opens sibling and child menus, previews symbols, works with the mouse, supports fuzzy filtering, falls back from LSP symbols to Tree-sitter, understands Markdown headings, and can switch terminal buffers.

The existing `<leader>uA` tabline toggle changes only the running Neovim process. The same inconsistency affects most other toggles. The statusline filename is the exception: it is already saved in `theme.json`. Toggle persistence should have one explicit owner, restore predictable defaults, and offer a clear recovery path if saved state causes trouble.

## Locked decisions

### Persist every currently installed toggle

All toggles in the current config and current LazyVim installation will be explicitly registered for persistence. This includes:

- formatting, both buffer and global;
- spelling and wrapping;
- relative and absolute line numbers;
- diagnostics;
- conceal level;
- tabline;
- Tree-sitter highlighting;
- dark background;
- animation;
- indent guides;
- smooth scrolling;
- inlay hints;
- Git signs;
- Dropbar;
- Precognition;
- statusline filename;
- dim, zoom, zen, profiler, and profiler highlights, subject to the startup exception below.

This rejects persisting only durable UI preferences because the requested behavior is that all toggles remember their choices. It also rejects limiting persistence to the four toggles directly involved in this change because that would leave the rest of the toggle interface inconsistent.

### Keep the current selection provider

Do not assign:

```lua
vim.ui.select = require("dropbar.utils.menu").select
```

Dropbar will own Breadcrumbs and Dropbar menus only.

Enabling Dropbar as the global selection provider has real benefits:

- one visual style for Dropbar and generic selection menus;
- numbered and Meta-letter shortcuts for direct selection;
- fuzzy filtering through the installed native fzf dependency;
- mouse hover and selection;
- optional preview and preview-close callbacks for callers that support them.

The costs outweigh those benefits for this config:

- the assignment changes every Neovim and plugin prompt that calls `vim.ui.select`, including code-action choices;
- LazyVim already supplies a selection UI, so two providers would compete through assignment and load order;
- a symbol-oriented menu and preview model is not necessarily clearer for generic lists;
- unrelated plugins would become coupled to Dropbar being loaded and configured;
- failures or behavior changes in Dropbar would affect prompts outside Breadcrumbs.

A future change can revisit this choice after trying Dropbar's own menus. It should be a deliberate global UI change with dedicated tests, rather than a side effect of replacing Breadcrumbs.

### Restore local toggles as future buffer defaults

Buffer-local toggles such as spelling, wrapping, line numbers, conceal, Tree-sitter, and inlay hints will save the last chosen value. On a later Neovim start, that value becomes the default for every buffer to which the option or feature applies.

This rejects saving state per absolute file path because that creates an unbounded history and makes moved files lose their settings. It rejects per-project state because the same file behavior would vary by working root and require another identity and cleanup policy.

The consequence must be documented: changing a local option for one buffer changes the default used for new buffers in later sessions. The implementation should not retroactively rewrite unrelated buffers in the current session unless the underlying toggle already does so.

### Do not reopen temporary modes on startup

Dim, zoom, zen, profiler, and profiler highlights are part of the registered inventory, but a fresh Neovim process always starts them off. Their last on-state must not reopen automatically.

This is a narrow exception to literal persistence. Restoring these modes could make a fresh launch unexpectedly zoomed or dimmed, and restoring the profiler would add startup work at the least useful time. Saving ordinary display and editing toggles remains unchanged.

Restoring these modes only for saved sessions was rejected because this config has no existing session-state contract for toggle restoration. Literal restoration was rejected because these are temporary working modes.

### Use a dedicated toggle-state store

Add a module such as `lua/toggle_state.lua` backed by:

```text
stdpath("state")/toggle-state.json
```

The module owns reading, validating, writing, and resetting toggle values. It exposes a small interface for registering a toggle with a stable key, reading its saved value with a default, saving a changed value, and deleting saved state.

The statusline filename moves from `theme.json` into the toggle store. For migration, the toggle module or statusline registration reads the old `theme.json` value only when the new key is absent. Once the filename changes, it is saved in the toggle store. Theme name and tint remain in `theme.json`.

Extending `theme.json` was rejected because colorscheme code should not own unrelated editor behavior. Moving theme and tint into a broad preferences store was rejected because it expands this change without improving toggle ownership.

### Register toggles explicitly

Persist the complete toggle inventory that exists when this work is implemented. Each adapter names the saved key, default value, restoration point, and get/set behavior. Adding a future toggle requires registering it deliberately.

A global wrapper around `Snacks.toggle` was rejected because it would depend on Snacks internals, infer semantics from arbitrary future plugins, and risk persisting one-shot actions. Persisting only `<leader>u` mappings was rejected because the Dropbar, Precognition, statusline, profiler, and window mappings do not all fit that namespace.

## Routine choices

- Lspsaga remains installed for rename and outline. Set `symbol_in_winbar.enable = false`, remove the Lspsaga Breadcrumbs redraw/autocommand code, and remove its ownership of `<leader>kb`.
- Install `Bekaboo/dropbar.nvim`.
- Install `nvim-telescope/telescope-fzf-native.nvim` as Dropbar's dependency with `build = "make"`. Dropbar consumes its native fzf support directly; this does not require changing the existing picker.
- Set `vim.o.mousemoveevent = true` so Dropbar's default bar and menu hover behavior works.
- Use Dropbar's default source chain: project-relative path plus LSP symbols with a Tree-sitter fallback, Markdown path plus headings, and terminal switching in terminal buffers.
- Keep Dropbar's truncation behavior for narrow windows.
- Reuse `<leader>kb` as the persistent Dropbar toggle.
- Add Dropbar's documented normal-mode mappings: `<leader>;` to pick a Breadcrumbs component, `[;` to jump to the current context start, and `];` to select the next context.
- Apply the Menu keys in both the normal Dropbar menu and its fuzzy prompt:
  - `Ctrl-h`: close the current menu, or leave fuzzy mode and return to the menu;
  - `Ctrl-j`: next entry;
  - `Ctrl-k`: previous entry;
  - `Ctrl-l`: open or accept the selected entry.
- Preserve Dropbar's existing `Enter`, `Escape`, `q`, mouse, and `i` mappings.
- Add `:ToggleStateReset`. It deletes `toggle-state.json`, reports that defaults will return after restart, and does not try to reverse every active option in the running process.
- Document the reset command and generated state-file path near the toggle-state module. This is the recovery note requested during the interview.

## Verified facts

### Current config

- `lua/plugins/ui.lua` enables Lspsaga Breadcrumbs through `symbol_in_winbar.enable = true`.
- The same file keeps only Lspsaga rename, outline, and Breadcrumbs; lightbulb and beacon are disabled.
- The current Breadcrumbs implementation uses a `BufEnter` autocmd and Lspsaga's private winbar modules to restore bars in buffers that attached while Breadcrumbs were hidden.
- `<leader>kb` currently toggles Lspsaga Breadcrumbs.
- `<leader>uA` is LazyVim's tabline toggle and changes `showtabline` between 0 and 2 without writing persistent state.
- Precognition uses `<leader>uP` and starts hidden on every launch.
- The statusline filename uses `<leader>uN` and already persists through `theme.json`.
- The existing Menu keys in completion and command-line menus use dismiss, next, previous, and accept semantics for `Ctrl-h/j/k/l`.
- `<leader>;`, `[;`, and `];` are free in the current config.
- `telescope-fzf-native.nvim` and Dropbar are not currently declared in the repository.

### Dropbar

- Dropbar requires Neovim 0.11 or later.
- `telescope-fzf-native.nvim` is optional in Dropbar generally and required for the fuzzy-menu behavior selected here.
- Dropbar's bar and menu hover options default to enabled and require `mousemoveevent`.
- The default source chain is path plus an LSP source with a Tree-sitter fallback; Markdown and terminal buffers receive specialized sources.
- Dropbar's normal menu defaults include click, Enter, Escape, `q`, mouse hover, and `i` to enter fuzzy mode.
- Dropbar's fuzzy prompt already maps `Ctrl-j` and `Ctrl-k` to next and previous.
- Dropbar officially supports replacing `vim.ui.select`, but doing so is optional.
- Dropbar's generic selector supports prompts, item formatting, optional preview callbacks, numbered shortcuts for the first nine items, and Meta-letter shortcuts for later items.

## Implementation shape

### Toggle-state module

The state file should contain a versioned JSON object with a `toggles` table keyed by stable names rather than display labels. Examples include `ui.tabline`, `ui.dropbar`, `editor.wrap`, and `lsp.inlay_hints`. Unknown keys should be preserved when a known key is updated so lazy-loaded registrations do not erase each other.

Malformed, missing, or wrong-typed state must fall back to registered defaults without preventing Neovim from starting. Writes should replace the state file atomically so an interrupted write cannot leave half a JSON document. Reset removes only toggle state; it must not delete theme or tint state.

Each registration needs:

- a stable key;
- its default;
- validation or coercion for the saved value;
- a restoration callback at the point when the owning option or plugin is available;
- a setter wrapper that saves only after the underlying change succeeds;
- an optional `restore = false` policy for temporary modes.

Native options can restore during normal config loading. Lazy plugin features restore in the owning plugin's `init` or `config` callback. A plugin registration must not force-load unrelated plugins merely to restore a value.

### Dropbar integration

Add Dropbar beside the other UI plugin specs. Its enable function must combine Dropbar's normal buffer/window eligibility with the saved Dropbar toggle. Turning it off clears only winbars owned by Dropbar. Turning it on attaches or refreshes eligible visible windows without overwriting another plugin's winbar.

The dependency declaration must build native fzf support with `make`. The config should extend Dropbar's default menu and fzf keymaps rather than replacing the full tables, so upstream mouse and Enter behavior remains present.

The Lspsaga spec keeps its existing rename and outline keys and setup, but disables Breadcrumbs. The which-key group can be renamed from “lspsaga” to a neutral navigation label if it still contains actions from both plugins; no key behavior depends on that label.

### Restoring LazyVim toggles

Replace or wrap the current LazyVim mappings only where needed to route state changes through the toggle-state module. Keep the existing keys and user-facing descriptions. Adapters should call the same Snacks or plugin APIs used by LazyVim so behavior stays familiar.

Local-option adapters save the last selected value as the next-start default and allow the original toggle to act on its current scope. Modal adapters remain registered for discoverability and future policy changes but do not restore an on-state.

## Acceptance criteria

- Lspsaga rename and outline still work.
- No Lspsaga Breadcrumbs appear.
- Dropbar Breadcrumbs appear in eligible file, Markdown, and terminal buffers.
- Dropbar uses the documented path and symbol fallback chain.
- `mousemoveevent` is enabled and mouse hover/click behavior works in the bar and menus.
- Fuzzy mode opens with `i` and filters through the native fzf dependency.
- `Ctrl-h/j/k/l` follow the Menu keys contract in normal and fuzzy Dropbar menus.
- `<leader>;`, `[;`, `];`, and `<leader>kb` perform their specified actions.
- Turning Dropbar off and restarting keeps it off; turning it on and restarting keeps it on.
- The tabline and every other registered ordinary toggle restore their last saved values after restart.
- Local toggle values become defaults for buffers opened after the next start.
- Dim, zoom, zen, profiler, and profiler highlights start off even if their last running state was on.
- Existing `theme.json` users keep their saved statusline filename through migration.
- `:ToggleStateReset` removes only toggle state and returns all registered toggles to defaults after restart.
- A missing, malformed, or partially invalid toggle-state file never prevents startup.
- `vim.ui.select` remains owned by the current provider.
- Tests cover state read/write/reset, old statusline migration, Dropbar config and keys, Lspsaga Breadcrumbs removal, local-default restoration, and modal non-restoration.

## Risks

- Persisting every toggle creates restoration-order work across native options and lazy-loaded plugins. Explicit adapters reduce the risk but require maintenance when LazyVim changes its toggle implementations.
- A local choice becomes a future global default. This is intentional, but it can surprise someone who toggled wrapping or spelling for one unusual file.
- Dropbar and another plugin can both want `winbar`. The enable and cleanup logic must respect existing non-Dropbar winbars.
- Native fzf compilation requires `make` and a working compiler toolchain. Plugin installation should fail visibly if the build cannot complete.
- Dropbar uses internal floating windows and previews. Custom Menu keys must call supported menu behavior and preserve upstream default mappings.
- The `vim.ui.select` decision may be revisited after real use. Enabling it later will require checking every important selection flow, especially LSP code actions and plugin prompts.
- State keys and defaults become compatibility surface. Renaming a key without migration silently resets that preference.
- Reset deliberately takes effect after restart. Users must not expect `:ToggleStateReset` to close active zoom, zen, or plugin UIs immediately.

## Deferred

None.

## Open threads

None. The recovery request is resolved by `:ToggleStateReset` and the documented state-file path.

