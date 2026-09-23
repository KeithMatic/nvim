# 06: lspsaga: Breadcrumbs, rename, outline

**What to build:** lspsaga provides only Breadcrumbs, rename and outline. Breadcrumbs appear at the top of the window and `<leader>uB` toggles them. `<leader>cr` renames with lspsaga (replacing LazyVim's LSP rename) and `<leader>cs` opens lspsaga's outline (replacing Trouble symbols; `<leader>cS` stays Trouble's LSP view). The keys are shown as a which-key "lspsaga" group. lspsaga's lightbulb, hover, code actions, diagnostics and finder are off. Its windows follow Transparency. This finishes the lspsaga part of the uncommitted UI experiments, with its lockfile entry.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Only symbol-in-winbar, rename and outline enabled
- [ ] `<leader>uB` checked free before binding
- [ ] `Saga` added to the Transparency prefixes
- [ ] Test: `<leader>cr`, `<leader>cs` and `<leader>uB` map to lspsaga; `<leader>cS` is still Trouble
- [ ] Test: the disabled features register no keys or lightbulb autocmds
- [ ] Test: `Saga*` groups have no background for each Curated theme
- [ ] Test: `<leader>uB` hides the Breadcrumbs and shows them again
- [ ] Manual: Breadcrumbs follow the cursor; rename and outline open in lspsaga's UI
