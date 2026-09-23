# nvim

My personal Neovim config. I moved to it from VS Code. It covers the languages I write, recreates the small VS Code extensions my muscle memory depends on, and is built for a translucent, blurred WezTerm window: the UI is transparent, and only the "where am I" indicators (cursor line, selection, completion item) are solid, tinted by mode. Theme (`<leader>uC`) and tint (`:Tint <#rrggbb> <fade 0-1>`) are chosen at runtime and remembered across restarts.

## Why LazyVim is still the base

I keep LazyVim as a lazy.nvim dependency because it gives me a curated, maintained set of defaults that keeps improving through `:Lazy update`, so this repo only has to hold what is personal to me.

## VS Code extensions → Neovim

| VS Code extension           | Neovim equivalent                                                               |
| --------------------------- | ------------------------------------------------------------------------------- |
| Smart Semicolon             | Own `semicolon` module: `;` goes to end of line in C-like filetypes, `;;` gives a literal |
| TabOut (taboutx)            | Own `tabout` module, called from the blink.cmp `<Tab>` chain                    |
| f-string converter          | nvim-puppeteer                                                                  |
| Backticks (template literals) | nvim-puppeteer                                                                |
| Code Runner                 | Own `runner` module: `<leader>cx` / `:RunFile` in a reused bottom terminal       |
| Colorize                    | `util.mini-hipatterns` extra                                                    |
| Path Intellisense           | blink.cmp path source (LazyVim default)                                         |
| Emmet (built in)            | emmet-language-server                                                           |
| Tailwind CSS IntelliSense   | `lang.tailwind` extra                                                           |
| Prettier                    | `formatting.prettier` extra                                                     |
| ESLint                      | `linting.eslint` extra                                                          |
| MDX                         | mdx-analyzer (`mdx` filetype)                                                   |

## Tests

```sh
tests/run.sh                      # every tests/*_spec.lua
tests/run.sh tests/boot_spec.lua  # one spec
```

Each spec boots the real config headlessly inside an isolated XDG sandbox in `.tests/` (separate config, data, state and cache), so a test run never touches my real Neovim state, saved theme or plugins. The first run, and any run after `lazy-lock.json` changes, installs plugins at their locked versions plus LazyVim's Mason tools and Treesitter parsers into the sandbox.

## Roadmap

- **html-end-tag-labels:** Treesitter virtual-text labels after closing HTML/JSX tags.
- **Floating-terminal runner:** a floating-window variant of the code runner, if the bottom split turns out not to suit.
