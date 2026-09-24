# 02: Language support

**What to build:** Opening a file in any language I use gives VS Code-level intelligence: LSP, formatting, linting and Treesitter highlighting. Every LazyVim extra is enabled explicitly and readably in one place: TypeScript, Python, Go, Rust, clangd, Tailwind, JSON, YAML, Docker, SQL, Markdown, TOML, plus Prettier formatting and ESLint linting. HTML, CSS, Emmet and MDX, which have no extras, are configured by hand, and MDX is recognised as its own filetype. Lua comes from LazyVim's core. Tooling installs automatically through Mason.

**Blocked by:** 01

**Status:** done

- [x] All listed extras are enabled as explicit imports (not through the interactive extras UI) and show as enabled in LazyVim's extras view
- [x] `.mdx` files get the `mdx` filetype
- [x] HTML, CSS, Emmet and MDX language servers are configured for their filetypes
- [x] Tests: for a representative file of each language, the expected LSP server is configured for that filetype and the expected formatter is registered (Prettier for the web stack)
- [x] No AI extras enabled
