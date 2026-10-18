# Snippet toggle for completion suggestions

A **Snippet toggle** hides or shows **Snippet suggestions** in the **Completion menu**. Off, it
hides every entry with the Snippet icon, whether from friendly-snippets or from a language server.
It's one choice for every buffer, saved in `toggle-state.json` like the other saved toggles, and
on by default (today's behaviour). It's flipped with `<leader>uk` in Normal mode. In Insert mode,
`<C-q>` flips it while the menu is open, and the menu redraws in place. Nothing new shows that
snippets are hidden: which-key's on/off icon and the toggle's notification are the signal, as for
every other saved toggle.

## Terms

These follow the glossary in `CONTEXT.md`. The first three were added to its Editing section in
this change.

- **Completion menu**: blink.cmp's list of suggestions while typing in Insert mode, the menu the
  **Menu keys** drive. _Avoid_: popup, autocomplete box, pum
- **Snippet suggestion**: an entry in the Completion menu that inserts a template with jump
  points, shown with the Snippet icon. It comes from friendly-snippets or from a language server.
  _Avoid_: snippet completion, template, abbreviation
- **Snippet toggle**: the saved switch that hides or shows Snippet suggestions: `<leader>uk`, or
  Ctrl-q while the Completion menu is open. _Avoid_: snippet mode, snippets on/off
- **Menu keys**: the Ctrl-h/j/k/l keys that drive an open Completion menu (dismiss, next,
  previous, accept) and move the cursor when none is open.

## Why

"I want to be able to toggle snippets on/off as I sometimes hate seeing snippets from completion
suggestions." Snippets crowd the Completion menu while typing ordinary code, and today the only
way to remove them is to edit the config.

## Locked decisions

No decision passed all three gates: hard to reverse, surprising without context, and a real
trade-off. Every choice below can be changed later in one place. They're still recorded in full,
with what each rejected option would have meant.

## Routine choices

- **Q1: what counts as a Snippet suggestion: anything with the Snippet icon (B).**
  - The toggle hides the `snippets` source's items (friendly-snippets) **and** language-server
    items of kind Snippet: lua_ls's `for`/`if`/`function`, rust-analyzer's and gopls's snippets.
  - It doesn't touch Function items that expand with argument placeholders. lua_ls's
    `callSnippet = "Replace"` still inserts calls with their arguments.
  - _Rejected_:
    - A, only the `snippets` source: language servers' Snippet items would still crowd the
      menu, so the toggle would look half-broken.
    - C, B plus function calls inserted bare: it changes what accepting a function does, not
      what the menu shows. That's a different feature, and it would surprise the first time a
      call landed without its arguments.
- **Q2: reach and memory: one choice everywhere, remembered across restarts (A).**
  - A saved toggle, registered in `lua/persistent_toggles.lua` and saved through
    `toggle_state.persist`, like `<leader>ud`.
  - `:ToggleStateReset` brings snippets back.
  - _Rejected_:
    - B, this session only: you'd have to hide them again after every restart.
    - C, per buffer with a saved default (a pair like `<leader>uf`/`<leader>uF`): a second key
      and restore code for a need nobody named.
- **Q3: what "off" does: Hidden (A).** No Snippet suggestion appears while off, from any source,
  whether the menu opened as you typed or with `<C-Space>`. If snippets were the only matches,
  the menu doesn't open.
  - _Rejected_:
    - B, Sunk (ranked last): they'd still fill short menus where little else matches.
    - C, hidden from the auto menu but shown when opened with `<C-Space>`: one more rule to
      remember, and the menu can't say why a snippet appeared.
- **Q4: where it's flipped from: a `<leader>u` key, plus an Insert-mode key while the menu is
  open (B).**
  - The Insert-mode key flips the same saved choice and redraws the menu in place without (or
    with) Snippet suggestions.
  - With the menu closed, the key falls back to its usual meaning (blink's `"fallback"`).
  - _Rejected_:
    - A, `<leader>u` only: flipping it mid-word leaves Insert mode, which autosaves the file
      (`lua/autosave.lua` saves on InsertLeave) and closes the menu.
    - C, an Insert-mode key that works whether or not the menu is open: it takes the key's own
      meaning everywhere in Insert mode, for nothing, since with no menu there's nothing to hide.
- **Q5: the `<leader>u` letter is `<leader>uk` (A).** k is for the Snippet kind it hides. Every
  letter for "snippet" is taken: `s` is spelling and `S` is smooth scroll.
  - _Rejected_:
    - B, `<leader>uj` ("jump points"): a weaker link.
    - C, `<leader>uX` ("cross out"): needs Shift, and the meaning is vague.
- **Q6: how you notice it's off: nothing new (A).** which-key shows the toggle's on/off icon
  under `<leader>u`, and flipping it posts the Snacks toggle notification, as for spelling,
  wrap or auto pairs.
  - _Rejected_:
    - B, a statusline mark: permanent clutter, and the only saved toggle with one.
    - C, a startup notification while hidden: noise on every start. The config's startup
      notifications are for problems, such as the Mix override warning.
- **Q7: the Insert-mode key is `<C-q>` (A).** It's the one free single Ctrl key in Insert mode.
  Its Vim meaning (insert a literal character) is a copy of `<C-v>`.
  - _Rejected_:
    - B, `<C-t>`: Insert-mode indent. Pressed out of habit while the menu was open, it would
      flip the toggle instead.
    - C, `<C-g>s`: clashes with nothing, but it's two presses for something meant to be instant.

### Following from the decisions (not asked)

- The toggle is a `Snacks.toggle` named "Snippet Suggestions", so which-key shows its state.
  Its saved key is `completion.snippets`, default `true` (shown).
- The README gets two rows, and the cheat sheet shows them, since it is the README:
  - `<leader>uk` in the `<leader>u` table ("Toggles and look");
  - `<C-q>` in Insert mode, in the table that lists the Menu keys, saying it works only with the
    menu open.

  The Editing feature list gets a **Snippet toggle** entry too. `tests/readme_spec.lua` doesn't
  enforce these rows: it checks only the keys `lua/config/keymaps.lua` defines.
- `<C-q>` goes in blink.cmp's `keymap` in `lua/plugins/editing.lua`, beside the Menu keys, as
  `{ <flip and redraw>, "fallback" }`. It isn't added to the cmdline keymap: no Snippet
  suggestions appear there.
- Turning snippets off doesn't affect a snippet already being filled in: `<Tab>`'s
  `snippet_forward` and autosave's mid-snippet rule stay as they are.

## Verified facts

- LazyVim's blink extra sets `sources.default = { "lsp", "path", "snippets", "buffer" }`
  (`lazyvim/plugins/extras/coding/blink.lua`). friendly-snippets is a dependency, read by blink's
  default snippets source. The database config ranks `dadbod` above snippets in SQL.
- blink.cmp (pinned `78336bc`) gives its own snippet items the kind Snippet, in every snippets
  backend: `sources/snippets/default/registry.lua`, `luasnip.lua`, `mini_snippets.lua` and
  `vsnip.lua`. So a single filter on `kind == Snippet` catches both the snippets source and the
  language servers' Snippet items.
- blink.cmp accepts a top-level `sources.transform_items(ctx, items)`, applied to every source's
  items, and a per-provider `enabled` (boolean or function)
  (`blink/cmp/config/sources.lua`).
- The filter can be one function: drop items whose kind is `CompletionItemKind.Snippet` while
  the toggle is off. It can also set the `snippets` provider's `enabled` to the toggle's state,
  so that source does no work while off. Either way, the setting must be read at request time
  (a function), not copied into the config at startup.
- `require("blink.cmp").show()` returns at once when the menu is already open, unless given
  `providers` (`blink/cmp/init.lua`). Redrawing in place after `<C-q>` therefore needs either
  `hide()` and then `show()`, or `show({ providers = … })`. Implementation settled this; see
  "Found during implementation".
- lua_ls's `Lua.completion.keywordSnippet` defaults to `"Replace"`: keywords come back as
  Snippet-kind items. LazyVim sets `Lua.completion.callSnippet = "Replace"`
  (`lazyvim/plugins/lsp/init.lua`).
- Insert-mode Ctrl keys in use:
  - `<C-s>`: LazyVim's save, or Neovim's signature help before VeryLazy;
  - `<C-b>`/`<C-f>`: docs scroll, from blink and noice;
  - `<C-e>`/`<C-a>`: line end/start, in this config;
  - `<C-h/j/k/l>`: the Menu keys;
  - `<C-n>`/`<C-p>`/`<C-y>`/`<C-Space>`: blink;
  - Vim's own `<C-r>`, `<C-o>`, `<C-w>`, `<C-u>`, `<C-v>`, `<C-x>`, `<C-g>`, `<C-d>`, `<C-t>`.

  `<C-q>` is free. Neovim runs the terminal in raw mode, so flow control doesn't take it.
- `<leader>u` letters taken across this config, LazyVim, Snacks and their extras: a A b c C d D e
  E f F g G h H i I l L m n N p P r s S t T w x y z Z. `<leader>uk` is free.
- `lua/autosave.lua` saves on InsertLeave, unless a snippet is active.
- Prior art for tests:
  - `tests/toggles_spec.lua`: a saved toggle survives a restart, through `toggle_state.reload()`;
  - `tests/menu_keys_spec.lua`: drives blink's menu in Insert mode, loads blink.cmp
    explicitly, and waits for its `<Tab>` map.

## Risks

- **Forgetting it's off.** The choice survives restarts and nothing on screen shows it (Q6 = A).
  The fix is a look at `<leader>u` in which-key. If this turns out to bite, Q6's B or C can be
  added later.
- **Redrawing the menu in place** depends on blink internals (`show()` returns early when the
  menu is open). Flipping with `<C-q>` might close the menu, or lose the selection, instead of
  redrawing it. A test should type a prefix with Snippet suggestions, press `<C-q>`, and check
  the menu stays open without them.
- **The terminal might take `<C-q>`.** The terminal app (`TERM_PROGRAM=Orca`) could bind it
  itself, for example to quit. You'd notice on the first press. Q7's C (`<C-g>s`) is the fallback.
- **Language servers that mislabel items.** A server that sends templates with another kind
  (such as Keyword or Text) gets past the filter. The toggle is about the Snippet kind, so that's
  accepted.
- **The `enabled` function and LazyVim.** If LazyVim later sets the `snippets` provider's
  `enabled` itself, a plain opts merge would replace it. Prefer the `transform_items` filter as
  the one rule, and treat `enabled` as an optional saving.

## Deferred

None.

## Open threads

None. Every question was answered with its recommendation.

## Found during implementation

- **One filter does both halves of Q1.** `lua/snippet_toggle.lua`'s `filter` is blink.cmp's
  top-level `sources.transform_items`. It drops items of the Snippet kind while hidden and is
  read each time a source's items are fetched. The `snippets` provider's `enabled` was left
  alone, as Risks suggested: one rule, nothing for LazyVim's opts to override.
- **The menu redraws with `cancel()` and then `show()`.** `cancel()` puts back the typed word a
  selected item's preview replaced (`hide()` would leave the preview in the line, and the new
  menu would match it). Its callback reopens the menu with the items fetched again. The selection
  starts over, since the selected item may be one of the hidden ones. If nothing else matches,
  the menu stays closed (Q3).
- **One toggle instance.** `<C-q>` flips the same `Snacks.toggle` that `persistent_toggles`
  wraps with its saving setter, so both keys save the choice and post the same notification.
- **An unmapped `<C-q>` swallows the next key.** Vim's own `<C-q>` inserts the next key
  literally, so a test that typed it with no mapping took the harness's closing `<Esc>` and
  hung. The `<C-q>` test now checks the mapping exists first.
- **The menu and restart seams** were agreed for the tests:
  - `tests/menu_keys_spec.lua`, "Snippet toggle": `<leader>uk` hides and shows; `<C-q>` hides in
    place and keeps the typed word; `<C-q>` with no menu inserts literally (a mutation that made
    it always flip was caught); a fake language server's Snippet item is hidden but its Function
    isn't.
  - `tests/toggles_spec.lua`: a fresh process with `completion.snippets = false` saved starts
    with them hidden.
- **Two test helpers moved into the harness.** The fake language server from
  `tests/startup/boot.lua` is now `h.fake_server(results, on_start)`, and `toggles_spec`'s
  `without_saved_toggles` is now `h.without_saved_toggles`, so the menu tests share them.
