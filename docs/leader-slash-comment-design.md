# Leader slash comment toggle

Add AstroNvim's Normal and Visual mode comment shortcuts to this LazyVim configuration: `<leader>/` toggles the current line or selected lines using the existing `gcc` and `gc` mappings. Keep the original mappings available and keep project search on `<leader>sg`.

## Terms

- **Comment toggle**: comment or uncomment the current line in Normal mode, or selected lines in Visual mode, using Neovim's existing commenting behavior. Avoid: none.

## Why

The user prefers AstroNvim's `<leader>/` shortcut to typing `gcc`, but wants to retain `gcc` as an option. The goal is to bring that shortcut into the current configuration without changing the existing language-aware commenting behavior.

## Locked decisions

None. These key mappings are routine, reversible configuration choices.

## Routine choices

- Use `<leader>/` for comments and retain project search on `<leader>sg` (Q1, accepted recommendation A). An additional search shortcut adds no needed capability.
- Match AstroNvim in both Normal and Visual modes, as requested: Normal maps to `gcc`, Visual maps to `gc`, both with `remap = true`.
- Preserve the existing `gcc` and `gc` mappings and comment engine, including its count, repeat, selection, and filetype behavior. Add no commenting plugin.
- Put the mappings in `lua/config/keymaps.lua`, which LazyVim loads on VeryLazy.

## Verified facts

- [AstroNvim's current mapping source](https://github.com/AstroNvim/AstroNvim/blob/main/lua/astronvim/plugins/_astrocore_mappings.lua), inspected on 2026-09-24, implements Normal `<Leader>/` as `gcc` and Visual `<Leader>/` as `gc`, with remapping enabled. This is a shortcut alias, not a separate commenting algorithm.
- Installed Neovim is v0.12.5. The installed LazyVim configuration uses `folke/ts-comments.nvim` to improve Neovim's native commenting behavior.
- LazyVim's installed Snacks picker configuration assigns project search to both `<leader>/` and `<leader>sg`; the former is replaced by the new Normal mode comment shortcut.
- Existing custom mappings live in `lua/config/keymaps.lua`.

## Risks

- Existing muscle memory for project search on `<leader>/` must change to `<leader>sg`.
- Comment syntax and mixed-selection behavior remain those of the existing comment engine. These aliases do not add support for otherwise unsupported filetypes.
- Plugin loading must not restore the old search mapping; verify the effective mapping after the full configuration loads.

## Deferred

None.

## Open threads

None.
