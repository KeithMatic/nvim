# 06: lspsaga: Breadcrumbs, rename, outline

**What to build:** lspsaga provides only Breadcrumbs, rename and outline. Breadcrumbs appear at the top of the window. lspsaga's keys sit under a which-key "lspsaga" group on `<leader>k`: `<leader>kr` renames, `<leader>ko` opens the outline and `<leader>kb` toggles the Breadcrumbs. LazyVim's `<leader>cr` and Trouble's `<leader>cs`/`<leader>cS` stay as they are. lspsaga's lightbulb, hover, code actions, diagnostics and finder are off. Its windows follow Transparency. This finishes the lspsaga part of the uncommitted UI experiments, with its lockfile entry.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Only symbol-in-winbar, rename and outline enabled
- [x] `<leader>k` checked free before binding
- [x] `Saga` added to the Transparency prefixes
- [x] Test: `<leader>kr`, `<leader>ko` and `<leader>kb` map to lspsaga under the `<leader>k` group; `<leader>cr`, `<leader>cs` and `<leader>cS` stay LazyVim's
- [x] Test: the disabled features register no keys or lightbulb autocmds
- [x] Test: `Saga*` groups have no background for each Curated theme
- [x] Test: `<leader>kb` hides the Breadcrumbs and shows them again
- [x] Manual: Breadcrumbs follow the cursor; rename and outline open in lspsaga's UI
