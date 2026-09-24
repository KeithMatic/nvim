-- The Database client, on trial: sqmeow.nvim in place of the lang.sql extra's
-- vim-dadbod-ui, which runs queries on the editor thread (freezing it on slow
-- ones) and shows results as plain text. sqmeow runs them in its own engine and
-- gives results that page, edit and export. vim-dadbod and vim-dadbod-completion
-- stay, for blink's SQL table and column completion.

-- The Database client: "sqmeow" or "dadbod-ui". Going back is this one line.
local client = "sqmeow"

-- The filetypes the lang.sql extra serves.
local sql_ft = { "sql", "mysql", "plsql" }

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
    -- Under <leader>D, where the extra kept dadbod-ui's toggle.
    keys = {
      { "<leader>Dd", "<cmd>Sqmeow toggle<cr>", desc = "Toggle Database" },
      { "<leader>Dc", "<cmd>Sqmeow cancel<cr>", desc = "Cancel Query" },
      { "<leader>Da", "<cmd>Sqmeow add<cr>", desc = "Add Connection" },
      { "<leader>Ds", "<cmd>Sqmeow scratch<cr>", desc = "New Scratchpad" },
      -- sqmeow only maps its run keys in its scratchpads; these run any SQL file.
      {
        "<leader>Dr",
        function()
          require("sqmeow.api").execute_statement()
        end,
        ft = sql_ft,
        desc = "Run Statement",
      },
      {
        "<leader>Dr",
        function()
          -- Leave visual mode first, so the '< and '> marks hold the selection.
          vim.cmd("normal! \27")
          require("sqmeow.api").execute_selection()
        end,
        mode = "x",
        ft = sql_ft,
        desc = "Run Selection",
      },
      {
        "<leader>De",
        function()
          require("sqmeow.api").execute_buffer()
        end,
        ft = sql_ft,
        desc = "Run File",
      },
    },
    opts = {},
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    enabled = client == "dadbod-ui",
  },
}
