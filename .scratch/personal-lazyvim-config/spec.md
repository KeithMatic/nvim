Status: ready-for-agent

# Personal LazyVim config: VS Code parity, full transparency, persistent themes

## Problem Statement

I'm moving from VS Code to Neovim and started from the LazyVim starter template. The starter is an opaque layer over a distro I didn't choose piece by piece. It doesn't know about the languages I write, it doesn't reproduce the small VS Code extensions my muscle memory depends on (smart semicolon, tab-out, f-string conversion, backtick conversion, code runner, colour swatches, path completion), and it doesn't look the way I want. I work in a translucent, blurred WezTerm window, but Neovim paints solid backgrounds everywhere, my theme choice is lost on restart, and nothing gives me a clear, calm indicator of where my cursor is. The repo also carries the starter's git history and licence, so it doesn't feel like *my* config.

## Solution

Keep LazyVim as the foundation, so it keeps receiving upstream updates through the plugin manager, and turn the repo into a small, clearly structured personal config with a fresh git history:

- Every language I use is enabled explicitly and readably as a LazyVim extra, with the few gaps (HTML, CSS, MDX) configured by hand.
- The VS Code extensions I rely on are reproduced with the smallest possible mechanism: an existing extra, a single plugin, or a short piece of code I own.
- The whole UI is transparent over the terminal's glass. Only the "where am I" indicators stay solid: the cursor line, the explorer line, the selected completion item and visual selections, tinted by mode.
- The theme and the tint colour are chosen at runtime and remembered across restarts.
- Plugin configuration and code I wrote live in clearly separate places, and a README records what everything is and what's planned.

## User Stories

### Foundation and structure
1. As the config owner, I want LazyVim to remain the base of my config, so that I get a curated, maintained set of defaults without assembling everything myself.
2. As the config owner, I want LazyVim and all plugins to update through the plugin manager's update command, so that I receive upstream improvements without merging a template.
3. As the config owner, I want a fresh git history that starts with my own first commit, so that the repo is clearly mine and not a fork of the starter.
4. As the config owner, I want the plugin lockfile committed, so that every plugin version is pinned and I can roll back a bad update.
5. As the config owner, I want every enabled LazyVim extra listed explicitly in one Lua location, so that I can see every language and tool I support at a glance.
6. As the config owner, I want plugin configuration kept separate from code I wrote myself, so that when something breaks I immediately know whether to look at a plugin spec or my own logic.
7. As the config owner, I want plugin configuration grouped into three concerns (languages, editing, UI), so that the config has as few files as possible while each one still has a single obvious purpose.
8. As the config owner, I want files created only when they have content, so that the config never contains empty placeholders.
9. As the config owner, I want the starter's example plugin file, starter README and starter licence removed, so that nothing in the repo is leftover template material.
10. As the config owner, I want LazyVim's default keybindings left untouched except where this spec explicitly says otherwise, so that I can rely on LazyVim's documentation for keys.

### Update awareness
11. As the config owner, I want the update checker to keep running silently, so that I'm not interrupted by pop-ups at startup.
12. As the config owner, I want a pending-updates count in the statusline, so that I know updates are available without being interrupted.

### Languages
13. As a TypeScript/React developer, I want TS/TSX/JS/JSX language support (LSP, formatting, linting, Treesitter), so that I get VS Code-level intelligence in those files.
14. As a Python developer, I want Python language support, so that I get completion, diagnostics and formatting.
15. As a Go developer, I want Go language support, so that I get completion, diagnostics and formatting.
16. As a Rust developer, I want Rust language support, so that I get completion, diagnostics and formatting.
17. As a C/C++ developer, I want clangd-based support, so that I get completion, diagnostics and formatting.
18. As a Lua developer, I want Lua support (including for this config itself), so that editing my config is well-supported.
19. As a web developer, I want HTML and CSS language servers, so that I get completion and diagnostics in markup and stylesheets.
20. As a web developer, I want Emmet abbreviations, so that I can expand markup quickly like in VS Code.
21. As a web developer, I want Tailwind class completion and colour previews, so that utility classes are as ergonomic as in VS Code.
22. As a developer, I want JSON, YAML and TOML support (including schema-aware completion where the extras provide it), so that config files are validated as I type.
23. As a developer, I want Dockerfile and compose support, so that container files get completion and diagnostics.
24. As a developer, I want SQL support, so that queries get highlighting and formatting.
25. As a writer, I want Markdown support, so that docs get highlighting, formatting and linting.
26. As a web developer, I want MDX files recognised and served by an MDX language server, so that MDX isn't treated as plain text.
27. As a web developer, I want Prettier as the formatter for the web stack, so that files come out identical whether formatted in Neovim or VS Code.
28. As a web developer, I want ESLint diagnostics, so that I see the same lint errors as in VS Code.
29. As a developer, I want language tooling installed automatically, so that a fresh machine is usable after the first launch.

### Completion and Tab behaviour
30. As a developer, I want `<Tab>` to accept the selected completion item when the menu is open, so that completion feels like VS Code.
31. As a developer, I want `<Tab>` to jump to the next snippet placeholder when I'm inside a snippet and no menu is open, so that snippets remain usable.
32. As a developer, I want `<Tab>` to move the cursor past the next character when it is a closing bracket or quote (`)`, `]`, `}`, `"`, `'`, backtick) and no menu or snippet applies, so that I can "tab out" like with the taboutx extension.
33. As a developer, I want `<Tab>` to insert normal indentation when none of the above applies, so that Tab still indents.
34. As a developer, I want that order to be fixed and guaranteed by a single owner of the key, so that the behaviour never depends on plugin load order.
35. As a developer, I want `<Enter>` to never accept a completion, so that pressing Enter for a newline never inserts an unwanted suggestion.
36. As a developer, I want to move through completion items with `<C-n>`/`<C-p>` and the arrow keys, so that I can pick something other than the first item.
37. As a developer, I want file-path completion when typing paths, so that I have path-intellisense parity.

### Smart editing
38. As a developer in a C-like language (JS, TS, JSX, TSX, C, C++, Rust, CSS/SCSS, Java-like), I want typing `;` anywhere in a line to put the semicolon at the end of the line, so that I don't have to navigate there first.
39. As a developer, I want typing `;` a second time immediately after that to insert a literal semicolon at the original cursor position, so that I can still type semicolons inside `for (;;)` loops or strings.
40. As a developer, I want `;` to stay completely normal in every other filetype (Python, Go, Lua, SQL, Markdown and others), so that smart semicolon never gets in the way where it makes no sense.
41. As a developer, I want the end-of-line semicolon not to be doubled when the line already ends with one, so that I never get `;;`.
42. As a Python developer, I want a normal string to become an f-string automatically when I type a `{…}` placeholder in it, so that I have fstring-converter parity.
43. As a JS/TS developer, I want a quoted string to become a template literal automatically when I type `${`, so that I have backticks-extension parity.
44. As a developer, I want colour values (hex codes, Tailwind colour classes) shown with their actual colour, so that I have colorize parity.

### Code runner
45. As a developer, I want to run the current file with `<leader>cx` or `:RunFile`, so that I have code-runner parity without leaving the editor.
46. As a developer, I want the runner's key to sit in LazyVim's existing "code" group, so that which-key shows it next to the other code actions.
47. As a developer, I want the runner to pick the command by filetype (Python with python3, Go with `go run`, JS with node, TS with `deno run`, Lua with `nvim -l`), so that one key works for all my languages.
48. As a Rust developer, I want `cargo run` inside a Cargo project and a compile-then-run of the single file otherwise, so that both projects and scratch files work.
49. As a C/C++ developer, I want the file compiled with clang/clang++ and then executed, so that scratch programs run with one key.
50. As a developer, I want the file saved before it runs, so that I always run what I see.
51. As a developer, I want output shown in a bottom split terminal that is reused between runs, so that output doesn't pile up in new windows.
52. As a developer, I want a clear message when the current filetype has no runner, so that I know why nothing happened.
53. As a developer, I want compiled binaries written outside my project, so that runs don't leave artefacts in the repo.

### Transparency
54. As a user of a translucent terminal, I want the editor background transparent, so that my terminal's blur shows through.
55. As a user of a translucent terminal, I want sidebars, the file explorer, the tab/bufferline, the sign column, line numbers and the end-of-buffer area transparent, so that no solid blocks break the glass effect.
56. As a user of a translucent terminal, I want the statusline fully transparent, with the current mode shown as coloured text instead of a solid pill, so that the statusline blends in but still shows the mode.
57. As a user of a translucent terminal, I want all floating windows (pickers, which-key, hover docs, completion menu, Lazy, Mason, notifications) transparent, so that the look is consistent everywhere.
58. As a user of a translucent terminal, I want every floating window to have a rounded border, so that transparent floats stay readable over the code behind them.
59. As a user of a translucent terminal, I want transparency applied again automatically every time any theme loads, so that switching themes never brings back solid backgrounds.

### Solid "where am I" indicators
60. As a developer, I want the cursor line in normal mode drawn as a solid, faded tint, so that I can always see which line I'm on over the glass.
61. As a developer, I want the cursor line in the file explorer drawn with the same tint, so that I can see which entry is selected.
62. As a developer, I want the selected completion item drawn with the same tint, so that I can see which suggestion Tab will accept.
63. As a developer, I want the cursor line and visual selection to change colour by mode (insert, visual, delete, yank), faded at a consistent level, so that I always know which mode I'm in from where I'm already looking.
64. As a developer, I want the per-mode colours taken from the current theme's palette, so that they always fit whichever theme is active.
65. As a developer, I want to change the tint colour and fade at runtime with a command taking a hex colour and a fade amount, so that I can adjust it while working without editing config.
66. As a developer, I want the tint applied immediately when I change it, so that I can try colours interactively.
67. As a developer, I want my tint remembered across restarts, so that I set it once.
68. As a developer, I want the tint to survive theme switches, so that choosing a new theme doesn't reset my indicator colour.
69. As a developer, I want a clear error when I pass an invalid colour or fade value, so that a typo doesn't break my highlights.

### Themes
70. As a user, I want tokyonight and catppuccin available, so that I can switch between the two families I like.
71. As a user, I want the colorscheme picker on LazyVim's `<leader>uC` key to list only my six dark themes (catppuccin frappe, macchiato, mocha and tokyonight night, storm, moon), so that I only choose from themes that look good transparent.
72. As a user, I want the picker to preview themes as I move through them, so that I can compare them before choosing.
73. As a user, I want whichever theme I last applied (from the picker or by typing the command) remembered and restored at startup, so that my choice persists.
74. As a user, I want a sensible default theme on first launch or when the saved theme no longer exists, so that startup never fails.
75. As a user, I want light themes excluded, so that I never land on an unreadable light-on-glass combination.

### Documentation
76. As the config owner, I want a README explaining what this config is and why it keeps LazyVim as its base, so that my future self understands the choice.
77. As the config owner, I want a table in the README mapping each VS Code extension I used to its Neovim equivalent, so that I know where each behaviour comes from.
78. As the config owner, I want a Roadmap section in the README, so that deferred ideas are written down instead of forgotten.

### Testing
79. As the config owner, I want an automated test run that boots my real config headlessly and checks the behaviours above, so that plugin updates that break my customisations are caught.
80. As the config owner, I want the tests isolated from my real Neovim state, so that running them never changes my saved theme, tint or plugin install.

## Implementation Decisions

- **Base:** LazyVim is kept as a plugin-manager dependency (lazy.nvim), not vendored or replaced. Extras are enabled as explicit imports in the plugin-manager bootstrap, placed after LazyVim's core import and before the user plugin imports, rather than through the interactive extras UI.
- **Extras enabled:** lang.typescript, lang.python, lang.go, lang.rust, lang.clangd, lang.tailwind, lang.json, lang.yaml, lang.docker, lang.sql, lang.markdown, lang.toml, formatting.prettier, linting.eslint, util.mini-hipatterns. Lua support comes from LazyVim's core. No AI extras.
- **Manual language support:** HTML, CSS, Emmet and MDX language servers are configured in the languages plugin group. MDX is registered as its own filetype. Tooling is installed through Mason, LazyVim's default.
- **Module layout (by concern, no paths):**
  - Core config: bootstrap + extras, options, keymaps (only the runner key), autocmds.
  - Plugin config, three groups: *languages*, *editing* (nvim-puppeteer, the completion Tab chain), *UI* (tokyonight, catppuccin, lualine, modes.nvim, float borders, the picker key override).
  - Custom modules (code the owner maintains): *theme* (transparency, persistence, tint, curated theme list), *runner*, *tabout*, *semicolon*.
- **Tab ownership:** the completion engine (blink.cmp) is the single owner of `<Tab>`. Its Tab chain is: accept → snippet forward → tabout → fallback. Tabout is a custom module called from that chain (no tabout.nvim). Enter is removed from accepting completions.
- **Tabout module interface:** a function that, when the character under the cursor in insert mode is a closer (`)`, `]`, `}`, `"`, `'`, backtick), moves the cursor past it and reports that it acted. Otherwise it reports that it did nothing, so the chain falls through.
- **Semicolon module interface:** set up per buffer for an explicit allow-list of C-like filetypes. In insert mode `;` appends a semicolon at end of line (never doubling an existing trailing one). An immediate second `;` undoes that and inserts a literal one at the original position. No shortcut-insertion variant.
- **Runner module interface:** a user command `:RunFile` plus `<leader>cx` (confirmed free in LazyVim's code group before binding). It resolves a command from a filetype → command table (Rust checks for a Cargo project, C/C++ compile to a temp location then execute), saves the buffer and sends the command to a single reused bottom split terminal. It exposes a **dry-run mode** that returns the resolved command without running it; this exists for tests. A floating-terminal variant is possible later.
- **Theme module interface:**
  - A curated list of six dark theme names.
  - A `ColorScheme` autocmd that (1) records the theme's original Normal background, (2) clears background on an explicit list of groups/prefixes (editor, sidebars, explorer, bufferline, lualine, floats, pickers, which-key, Lazy/Mason, notifications, completion menu), (3) re-applies the tint to the cursor line, explorer cursor line and completion selection by blending the tint colour with the recorded background at the fade amount, producing a solid hex background, and (4) saves the theme name.
  - A user command `:Tint <hex> <fade>` that validates input, applies it immediately and saves it.
  - A startup restore that reads the saved theme (falling back to a default such as tokyonight-moon when it's missing or invalid) and passes it to LazyVim's colorscheme option.
  - Persistence: a single small state file in Neovim's state directory holding the theme name, tint colour and fade.
- **Themes:** tokyonight and catppuccin both configured with their native transparent/float-transparent options. The theme module's autocmd is the catch-all for everything else.
- **Statusline:** lualine sections get transparent backgrounds. The mode component uses mode-coloured foreground text. A lazy.nvim pending-updates component is added. The update checker stays enabled with notifications off.
- **Mode tint:** modes.nvim handles insert, visual, delete and copy line/selection colours, taken from the active theme's palette, with a consistent line opacity. Normal-mode, explorer and completion-selection tint come from the theme module, not modes.nvim.
- **Picker:** LazyVim's `<leader>uC` is overridden to open a colorscheme picker limited to the curated list, with live preview. This is the only change to an existing LazyVim key. Persistence doesn't depend on the picker, because saving happens in the `ColorScheme` autocmd.
- **Floats:** rounded borders everywhere floats are created (LSP hover/signature, completion menu and docs, pickers, which-key, Lazy, Mason, notifications).
- **Repo:** the starter's git history is removed and a fresh repository is initialised. The lockfile and LazyVim's JSON state file are tracked. The starter's example plugin file, README and licence are removed. stylua and neoconf config are kept.

## Testing Decisions

- **One seam:** a headless Neovim instance booting the real config inside an isolated XDG sandbox (separate config/data/state/cache), so tests never touch the owner's real saved theme, tint or plugins. All assertions are on externally observable behaviour: buffer text, cursor position, highlight-group attributes, command results and state after a restart. No test reaches into a module's local functions.
- **What a good test looks like here:** drive the editor the way a user would (feed keys, run commands, load themes), then assert on what the user would see. A test must not care *how* transparency or the Tab chain is implemented, only that the result is correct.
- **Covered behaviours:**
  - Semicolon: in a TS buffer `;` mid-line ends up at end of line; a double `;` gives a literal; an already-terminated line is not doubled; in a Python buffer `;` is inserted literally.
  - Tab chain: before a closer the cursor moves past it; in plain text an indent is inserted; with the completion menu open the selected item is accepted; Enter with the menu open inserts a newline.
  - Runner (dry-run): the resolved command for python, go, js, ts (deno), lua, rust inside and outside a Cargo project, c and cpp; an unsupported filetype reports "no runner".
  - Transparency: for each of the six themes, Normal, NormalFloat, SignColumn, StatusLine and lualine section groups have no background; CursorLine, Visual and the completion selection do.
  - Persistence: applying a theme and then booting a second headless instance restores it; the same for `:Tint`, including the expected blended CursorLine colour; an invalid saved theme falls back to the default.
  - Picker: the `<leader>uC` source yields exactly the six curated names.
- **Prior art:** none in this repo. LazyVim's own test suite (busted via lazy.nvim's minimal-init helper) is the reference for bootstrapping plugins in a headless test environment.

## Out of Scope

- html-end-tag-labels (Treesitter virtual-text labels after closing tags). Deferred to the README Roadmap.
- A floating-terminal runner. Deferred to the Roadmap; revisit if the bottom split doesn't work well.
- AI completion or chat (Copilot, Supermaven, CodeCompanion and similar).
- Any change to LazyVim's default keybindings other than the `<leader>uC` override and the Tab/Enter/`;` insert-mode behaviours described above.
- Light themes and any themes beyond the six curated ones.
- Debugger (DAP), test-runner integration and multi-cursor editing.
- Deno *project* support (denols); `deno` is used only as the runner for single TS files.
- The semicolon-insertion shortcut variant.
- Replacing LazyVim with a from-scratch or native package-manager config.

## Further Notes

- The target terminal is WezTerm with window background opacity 0.5, background blur, and text background opacity 1. That last setting is what makes the tinted indicators render as solid bars over the glass. Transparency will look different in terminals without these settings.
- The target Neovim version is 0.12.x.
- All runner toolchains (python3, go, cargo/rustc, clang/clang++, node, deno) are already installed on the target machine.
- Before building, check against LazyVim's current source: that `<leader>cx` is free, the highlight-group names blink.cmp and the explorer use for their selected line, and how LazyVim wires the completion keymap preset, so that the Tab chain overrides it cleanly.
- The README should state briefly why LazyVim was kept as a base despite the goal of "my own setup", instead of a formal ADR.
