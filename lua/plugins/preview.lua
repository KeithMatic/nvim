-- The Browser group (<leader>v): the Markdown preview (mdkite.nvim, in place
-- of the markdown extra's markdown-preview.nvim) and the Live server
-- (kitehost.nvim). Both are pure Lua, load on their key or command, and never
-- start on their own. See docs/mdkite-kitehost-design.md.

return {
  -- mdkite's predecessor; going back is flipping this and dropping mdkite.
  { "iamcco/markdown-preview.nvim", enabled = false },
  {
    "selimacerbas/mdkite.nvim",
    dependencies = { "selimacerbas/kitehost.nvim" },
    cmd = "MdKite",
    keys = {
      -- <leader>cp is the key the markdown extra gave markdown-preview.nvim.
      { "<leader>cp", "<cmd>MdKite toggle<cr>", ft = "markdown", desc = "Toggle Markdown Preview" },
      { "<leader>vm", "<cmd>MdKite toggle<cr>", ft = "markdown", desc = "Toggle Markdown Preview" },
    },
    -- Both are mdkite's defaults, pinned so an upstream change can't move them.
    opts = {
      mermaid_renderer = "js", -- mermaid.js in the browser: no mmdr binary
      instance_mode = "takeover", -- one tab; the newest Neovim to start it takes over
    },
  },
  {
    -- Its pickers fall back to vim.ui.select/input, which Snacks draws: no telescope.
    "selimacerbas/kitehost.nvim",
    cmd = "KiteHost",
    keys = {
      { "<leader>vs", "<cmd>KiteHost start<cr>", desc = "Start Live Server" },
      { "<leader>vx", "<cmd>KiteHost stop<cr>", desc = "Stop Live Server" },
      { "<leader>vX", "<cmd>KiteHost stop-all<cr>", desc = "Stop All Live Servers" },
      { "<leader>vi", "<cmd>KiteHost status<cr>", desc = "Live Server Status" },
    },
    opts = { auto_start = false }, -- the Live server starts only when asked
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      -- Appended: a list in opts would replace LazyVim's groups, not add to them.
      table.insert(
        opts.spec,
        { "<leader>v", group = "browser", icon = { icon = vim.trim(require("util.icons").misc.Globe), color = "blue" } }
      )
    end,
  },
}
