-- Layers (lua/layer.lua): keys laid over the usual ones until you leave.
-- Their help window looks like every other float: the theme's float colours
-- over the glass, and a rounded border.
return {
  {
    "debugloop/layers.nvim",
    lazy = true, -- loaded by the first layer to need it
    opts = {
      mode = {
        window = {
          opts = { winhl = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle" },
        },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      {
        "<leader>gH",
        function()
          require("layer.git"):enter()
        end,
        desc = "Git Layer",
      },
    },
  },
}
