-- The Database client, on trial: sqmeow.nvim in place of the lang.sql extra's
-- vim-dadbod-ui, which runs queries on the editor thread (freezing it on slow
-- ones) and shows results as plain text. sqmeow runs them in its own engine and
-- gives results that page, edit and export. vim-dadbod and vim-dadbod-completion
-- stay, for blink's SQL table and column completion, pointed at the database
-- sqmeow runs queries on.

-- The Database client: "sqmeow" or "dadbod-ui". Going back is this one line.
local client = "sqmeow"

local sql_ft = require("database").sql_ft

--- The URL of the database queries from `buf` run on in sqmeow, for vim-dadbod,
--- or nil when there's none it can reach.
local function sqmeow_db_url(buf)
  local connection = require("sqmeow.api").target(buf)
  -- A database behind an SSH tunnel is only reachable through sqmeow's engine.
  if not connection or connection.state ~= "connected" or connection.ssh then
    return nil
  end
  if not connection.database then
    return connection.url
  end
  -- One database of a cluster: its URL names the cluster, so the database goes in the path.
  local authority, rest = connection.url:match("^(%w[%w+.-]*://[^/?#]*)(.*)$")
  if not authority then
    return nil
  end
  return authority .. "/" .. connection.database .. (rest:match("[?#].*$") or "")
end

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
    config = function(_, opts)
      require("sqmeow").setup(opts)
      -- The database is named by the first Breadcrumb (lua/database.lua), not
      -- sqmeow's winbar, which would stand in for the Breadcrumbs in a
      -- scratchpad or bound buffer. sqmeow calls this whenever that database
      -- may have changed: a switch, a bind, a connection opening or closing.
      require("sqmeow.ui.editor").update_winbar = require("database").refresh
    end,
    init = function()
      -- Every SQL buffer gets the keys sqmeow gives its scratchpads (<CR> runs
      -- the statement or selection, <leader>E the buffer, <C-c> stops). Not
      -- editor.attach(), which would untie a :Sqmeow bind.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("sqmeow_sql_keys", { clear = true }),
        pattern = sql_ft,
        callback = function(ev)
          local actions = require("sqmeow.ui.editor").actions
          require("sqmeow.keymap").apply("editor", ev.buf, actions)
          -- sqmeow has a help action for these keys but maps it to nothing,
          -- and its keymap overrides can only move keys, not add them.
          -- This takes ? (backward search) in SQL buffers.
          vim.keymap.set("n", "?", actions.help, { buffer = ev.buf, desc = "sqmeow: Show these mappings" })
        end,
      })
      -- The Menu keys walk the drawer's tree: <C-j>/<C-k> down and up, <C-l>
      -- opens (or steps into what is open), <C-h> closes (or steps out to the
      -- parent). They take the drawer's window moves; <C-w> still has them.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("sqmeow_drawer_keys", { clear = true }),
        pattern = "sqmeow-drawer",
        callback = function(ev)
          local drawer = require("sqmeow.ui.drawer")
          local function open_node()
            local node = drawer.current_node()
            return node and node.expandable and node:is_expanded() and node
          end
          local keys = {
            ["<C-j>"] = { "j", "Down" },
            ["<C-k>"] = { "k", "Up" },
            ["<C-l>"] = {
              function()
                if open_node() then
                  vim.cmd("normal! j")
                else
                  drawer.actions.toggle()
                end
              end,
              "Open the node",
            },
            ["<C-h>"] = {
              function()
                if open_node() then
                  return drawer.actions.toggle()
                end
                local node = drawer.current_node()
                local parent = node and node:get_parent_id()
                if not parent then
                  return
                end
                -- The drawer finds nodes only under the cursor, and indents
                -- leaves past their open siblings, so walk up to the parent.
                local start = vim.api.nvim_win_get_cursor(0)
                for above = start[1] - 1, 1, -1 do
                  vim.api.nvim_win_set_cursor(0, { above, 0 })
                  local candidate = drawer.current_node()
                  if candidate and candidate:get_id() == parent then
                    return
                  end
                end
                vim.api.nvim_win_set_cursor(0, start)
              end,
              "Close the node, or go to its parent",
            },
          }
          for lhs, map in pairs(keys) do
            vim.keymap.set("n", lhs, map[1], { buffer = ev.buf, nowait = true, desc = "sqmeow: " .. map[2] })
          end
        end,
      })
      -- dadbod completion reads b:db and knows nothing of sqmeow, so point it at
      -- sqmeow's database each time insert mode starts, where completion happens.
      -- A b:db set by hand (anything but what this last set) is left alone.
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = vim.api.nvim_create_augroup("sqmeow_dadbod_db", { clear = true }),
        callback = function(ev)
          local b = vim.b[ev.buf]
          if not vim.list_contains(sql_ft, vim.bo[ev.buf].filetype) or (b.db ~= nil and b.db ~= b.sqmeow_db) then
            return
          end
          local url = sqmeow_db_url(ev.buf)
          b.db = url
          b.sqmeow_db = url
        end,
      })
    end,
    -- Under <leader>D, where the extra kept dadbod-ui's toggle.
    keys = {
      { "<leader>Dd", "<cmd>Sqmeow toggle<cr>", desc = "Toggle Database" },
      { "<leader>Dc", "<cmd>Sqmeow cancel<cr>", desc = "Cancel Query" },
      { "<leader>Da", "<cmd>Sqmeow add<cr>", desc = "Add Connection" },
      { "<leader>Ds", "<cmd>Sqmeow scratch<cr>", desc = "New Scratchpad" },
      {
        "<leader>Db",
        function()
          require("database").pick(vim.api.nvim_get_current_buf())
        end,
        ft = sql_ft,
        desc = "Switch Database",
      },
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
  -- Tables and columns from the database before snippets and keywords, as
  -- LazyVim ranks lazydev in Lua.
  {
    "saghen/blink.cmp",
    optional = true,
    opts = { sources = { providers = { dadbod = { score_offset = 100 } } } },
  },
}
