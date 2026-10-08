-- The Terminal manager (lua/terminal.lua): nvzone/floaterm, on <C-/> and
-- <leader>ft/fT (lua/config/keymaps.lua), loaded when first used.
-- See docs/floaterm-design.md.
return {
  {
    "nvzone/floaterm",
    dependencies = { "nvzone/volt" },
    cmd = "FloatermToggle",
    opts = function()
      return require("terminal").opts
    end,
    config = function(_, opts)
      require("terminal").setup(opts)
    end,
  },
  { "nvzone/volt", lazy = true },
}
