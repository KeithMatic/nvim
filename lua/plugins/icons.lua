-- The Icon set (lua/util/icons.lua) feeds LazyVim's `icons` option, so completion
-- kinds, diagnostics, the statusline, Trouble and which-key all draw from it.
local icons = require("util.icons")

local git_signs = {
  add = { text = icons.git.added },
  change = { text = icons.git.modified },
  delete = { text = icons.git.removed },
  topdelete = { text = icons.git.removed },
  changedelete = { text = icons.git.modified },
  untracked = { text = icons.git.added },
}

local toml = { glyph = icons.misc.toml }

return {
  { "LazyVim/LazyVim", opts = { icons = icons } },
  -- LazyVim hard-codes the gutter's git signs rather than reading its icons.
  { "lewis6991/gitsigns.nvim", opts = { signs = git_signs, signs_staged = git_signs } },
  -- mini.icons also answers for nvim-web-devicons, so this reaches the Explorer,
  -- statusline, picker and bufferline.
  {
    "nvim-mini/mini.icons",
    opts = {
      extension = { toml = toml },
      filetype = { toml = toml },
    },
  },
}
