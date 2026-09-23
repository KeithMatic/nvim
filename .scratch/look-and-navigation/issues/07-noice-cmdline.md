# 07: Noice cmdline

**What to build:** The cmdline popup sits in the exact centre of the screen. Each cmdline kind (command, search, Lua, help, filter, shell) shows its icon from the Icon set. The completion menu opens one row below the popup's bottom border, so the two borders never overlap. The popup settings move to where noice reads them (the current preset-nested settings are ignored). This finishes the noice part of the uncommitted UI experiments.

**Blocked by:** 02 (Icon set)

**Status:** ready-for-agent

- [ ] Popup position and size set in noice's top-level views, not inside the preset
- [ ] Cmdline format icons come from the Icon set
- [ ] The cmdline completion menu is positioned from noice's cmdline position, one row lower
- [ ] Test: the cmdline popup is centred horizontally and vertically
- [ ] Test: with the cmdline completion menu open, its top row is one row below the popup's bottom border
- [ ] Test: the boot spec still passes
- [ ] Manual: `:`, `/` and `:lua` show their icons; the gap between cmdline and menu looks right
