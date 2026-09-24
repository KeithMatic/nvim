# 07: Noice cmdline

**What to build:** The cmdline popup sits in the exact centre of the screen. Each cmdline kind (command, search, Lua, help, filter, shell) shows its icon from the Icon set. The completion menu opens one row below the popup's bottom border, so the two borders never overlap. The popup settings move to where noice reads them (the current preset-nested settings are ignored). This finishes the noice part of the uncommitted UI experiments.

**Blocked by:** 02 (Icon set)

**Status:** done

- [x] Popup position and size set in noice's top-level views, not inside the preset
- [x] Cmdline format icons come from the Icon set
- [x] The cmdline completion menu is positioned from noice's cmdline position, one row lower
- [x] Test: the cmdline popup is centred horizontally and vertically
- [x] Test: with the cmdline completion menu open, its top row is one row below the popup's bottom border
- [x] Test: the boot spec still passes
- [x] Manual: `:`, `/` and `:lua` show their icons; the gap between cmdline and menu looks right

## Comments

- The preset-nested settings weren't wholly ignored: noice merges a preset table into its config, so `row = "40%"` applied (the popup sat high). Only the misspelled `cmdline_popup_menu` view was ignored. Top-level `views` are merged after the presets, so they win over LazyVim's `command_palette`.
- "filter" and "shell" are one noice format, `filter` (`:!`, run in the shell), with the Icon set's Terminal glyph. noice's `input` and `calculator` formats keep noice's glyphs. The Icon set gained `misc.lua` (the glyph mini.icons draws for Lua files).
- The menu's top border sits on the row right after the popup's bottom border (no blank row between). If a blank row is wanted, it's a one-line change in `cmdline_position` and the test.
- The menu row comes from noice's cmdline frame, so LazyVim's bottom search (no border, menu above) keeps blink's default placement; a test covers that.
