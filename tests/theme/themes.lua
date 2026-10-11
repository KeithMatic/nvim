-- Not lua/config/themes.lua: what mix_spec.lua and theme_spec.lua (and the
-- second Neovim they boot) read in its place, so they check the config's code
-- whatever themes are added there. The defaults: no themes added, and the Mix
-- of tokyonight-moon's UI and catppuccin-mocha's code colours.
return {
  added = {},
  mix = {
    ui = "tokyonight-moon",
    syntax = "catppuccin-mocha",
    overrides = {
      from = {},
      set = {},
    },
  },
}
