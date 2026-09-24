# 03: TOML glyph

**What to build:** TOML files show a glyph that renders in the target terminal (WezTerm, Symbols Nerd Font Mono fallback) in the Explorer, statusline, picker and bufferline. The default glyph (U+E6B2) is missing from the fallback font. The owner chooses the replacement from three candidates shown in their terminal; it is set as an icon-provider override for both the `toml` extension and filetype.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Three candidate glyphs shown to the owner in their terminal; the owner picks one (U+E615, seti config)
- [x] Override covers the `toml` extension and the `toml` filetype
- [x] Test: the icon provider returns the chosen glyph for `Cargo.toml`, `pyproject.toml` and the `toml` filetype
- [x] Manual: the glyph renders in the bufferline, picker and statusline
