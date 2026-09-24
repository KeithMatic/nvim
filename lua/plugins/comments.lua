return {
  { "folke/ts-comments.nvim", enabled = false },
  {
    "celeste3z/celeste_comment.nvim",
    -- Upstream permits breaking changes in minor releases; update deliberately.
    commit = "b39441f1bb84a925e57299db78719ed8361b809c",
    event = "VeryLazy",
    main = "celeste_comment",
    opts = {
      keep_cursor = true,
      keep_selection = "adjust | keep_visual",
      mappings = {
        line_toggle_insert = { "<M-/>", "<M-_>" },
        line_add_eol = "gcA",
        uncomment_auto = "gcu",
        line_invert = "gcI",
        line_force_add = "gCC",
        line_force_remove = "gCU",
      },
    },
  },
}
