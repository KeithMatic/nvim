-- The themes you add and the Mix: the one file to edit for either. Read by
-- lua/plugins/ui.lua (the plugins), lua/curated_themes.lua (the Curated themes) and
-- lua/mix.lua (the Mix). See docs/converge-mix-design.md.
return {
  -- Paste a theme's plugin repo to offer every dark theme it ships in the
  -- theme picker (<leader>uC). The first time the picker opens after adding
  -- one, its themes are read once (a brief pause) to drop the light ones.
  -- A table narrows it to some of its themes, or passes options to its setup():
  --   "rebelot/kanagawa.nvim",
  --   { "rebelot/kanagawa.nvim", variants = { "kanagawa-dragon" }, opts = { theme = "dragon" } },
  -- Transparency is applied to every theme, so leave a theme's own transparency
  -- option off: it hides the background the Tint is faded over.
  added = {
    "olimorris/onedarkpro.nvim",
    "AlexvZyl/nordic.nvim",
    "everviolet/nvim",
    "rebelot/kanagawa.nvim",
    "wilmanbarrios/palenight.nvim",
    "dgox16/oldworld.nvim",
    "gbprod/nord.nvim",
    "Aejkatappaja/cendre",
    "JoosepAlviste/palenightfall.nvim",
    "uhs-robert/oasis.nvim",
    "2giosangmitom/nightfall.nvim",
  },

  -- The Mix: the editor's UI from one Curated theme, the code's colours from
  -- another, applied as the theme `converge` (converge.nvim's `recipe`).
  -- Overrides change single highlight groups: `from` takes them from another
  -- theme, `set` gives your own colours (vim.api.nvim_set_hl's format). One the
  -- config sets itself (the Tint, Transparency, Mode colours, ...) is replaced
  -- by it, and reported at startup. Names with `-`, `.` or `@` go in ["..."].
  mix = {
    ui = "tokyonight-moon",
    syntax = "onedark",
    overrides = {
      from = {},
      set = {},
    },
  },
}
