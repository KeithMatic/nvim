-- UI: the themes and their transparency, the statusline, mode colours, float
-- borders the 'winborder' option doesn't reach, and the curated theme picker.
-- Transparency the themes' own options leave out, and the tint, are done in
-- lua/theme.lua.

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
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = { sidebars = "transparent", floats = "transparent" },
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      transparent_background = true,
      float = { transparent = true },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.theme = require("theme").lualine
      -- No powerline arrows: they'd be drawn in the (now cleared) section colours.
      opts.options.section_separators = { left = "", right = "" }
    end,
  },
  {
    -- Tints the cursor line and selection by mode. Its colours come from the
    -- theme's palette: lua/theme.lua sets them on every theme change.
    "mvllow/modes.nvim",
    event = "VeryLazy",
    opts = {
      line_opacity = 0.2,
      set_cursorline = false, -- leave 'cursorline' on everywhere, as LazyVim sets it
    },
    config = function(_, opts)
      -- It fades its colours over Normal's background, which transparency clears.
      require("theme").with_background(function()
        require("modes").setup(opts)
      end)
    end,
  },
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true, -- LSP hover and signature help
        -- Configure the centered command palette
        command_palette = {
          views = {
            cmdline_popup = {
              position = { row = "40%", col = "50%" },
              size = { width = "20%", max_width = 50 },
            },
            cmdline_popup_menu = {
              position = { row = "10%", col = "10%" },
              size = { width = "10%", max_width = 10 },
            },
          },
        },
      },
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
