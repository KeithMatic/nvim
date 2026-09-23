-- The Database client, on trial: sqmeow.nvim in place of the lang.sql extra's
-- vim-dadbod-ui. vim-dadbod and vim-dadbod-completion stay, for blink's SQL
-- table and column completion.

-- The Database client: "sqmeow" or "dadbod-ui". Going back is this one line.
local client = "sqmeow"

return {
  {
    "2giosangmitom/sqmeow.nvim",
    enabled = client == "sqmeow",
    dependencies = { "MunifTanjim/nui.nvim" },
    version = "*", -- the engine is downloaded for the release the plugin is on
    build = function()
      require("sqmeow").install()
    end,
    cmd = "Sqmeow",
    opts = {},
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    enabled = client == "dadbod-ui",
  },
}
