-- UI: the theme LazyVim starts with, and the curated theme picker.

return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Restores the last theme applied (see lua/theme.lua).
      colorscheme = function()
        require("theme").load()
      end,
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      -- The only change to an existing LazyVim key: same picker, curated themes.
      {
        "<leader>uC",
        function()
          require("theme").pick()
        end,
        desc = "Colorschemes",
      },
    },
  },
}
