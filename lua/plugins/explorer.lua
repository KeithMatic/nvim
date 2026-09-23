-- The Explorer: neo-tree, from LazyVim's neo-tree extra (imported in
-- lua/config/lazy.lua, which also retires the Snacks explorer), with only my
-- differences on top: Files and Git tabs, the Explorer position, <leader>o, the
-- Icon set's glyphs, what's shown and hidden, and the Git tab's keys.
-- Its Transparency and Tint are done in lua/theme.lua.

-- The Explorer position: "float" (centred, borderless), "left" or "right".
local position = "float"

local icons = require("util.icons")

--- Whether `win` shows the Explorer.
local function is_explorer(win)
  return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree"
end

--- <leader>o. Floating: open the Explorer on the current file, or close it.
--- Docked: jump to the Explorer, revealing the current file, or back again.
local function show_where_i_am()
  local command = require("neo-tree.command")
  local where = require("neo-tree").ensure_config().filesystem.window.position
  if where == "float" then
    if vim.iter(vim.api.nvim_tabpage_list_wins(0)):any(is_explorer) then
      return command.execute({ action = "close", position = "float" })
    end
  elseif is_explorer(vim.api.nvim_get_current_win()) then
    return vim.cmd.wincmd("p")
  end
  command.execute({ action = "focus", source = "filesystem", position = where, reveal = true, dir = LazyVim.root() })
end

--- Even out the other windows when a docked Explorer opens or closes.
local function rebalance(args)
  if args.position == "left" or args.position == "right" then
    vim.cmd.wincmd("=")
  end
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<leader>o", show_where_i_am, desc = "Explorer (Current File)" },
      { "<leader>be", false }, -- no buffers source: bufferline shows open buffers
    },
    opts = function(_, opts)
      opts.sources = { "filesystem", "git_status" }
      opts.close_if_last_window = true
      opts.sort_case_insensitive = true
      -- Labels on the left, no border between the tabs. The dashed line under them
      -- is part of their highlights (lua/theme.lua).
      opts.source_selector = {
        winbar = true,
        content_layout = "left",
        separator = "",
        sources = {
          { source = "filesystem", display_name = " " .. icons.ui.Files .. "Files " },
          { source = "git_status", display_name = " " .. icons.git.Git .. "Git " },
        },
      }
      opts.window = vim.tbl_deep_extend("force", opts.window or {}, {
        position = position,
        width = 35,
        popup = { border = "none" },
      })
      opts.default_component_configs = vim.tbl_deep_extend("force", opts.default_component_configs or {}, {
        indent = { indent_marker = icons.ui.LineDashedMiddle },
        icon = {
          folder_closed = icons.ui.FolderAlt,
          folder_open = icons.ui.FolderOpenAlt,
          folder_empty = icons.ui.FolderAlt,
          folder_empty_open = icons.ui.FolderEmptyOpenAlt,
        },
        modified = { symbol = icons.ui.Modified },
        git_status = { symbols = icons.file_status },
        symlink_target = { enabled = true },
      })
      opts.filesystem = vim.tbl_deep_extend("force", opts.filesystem or {}, {
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
          -- Hidden; H shows it. (neo-tree merges this over its own list, which
          -- names the two below: never_show is what keeps those away.)
          hide_by_name = { "node_modules" },
          never_show = { ".DS_Store", "thumbs.db" },
        },
      })
      opts.git_status = vim.tbl_deep_extend("force", opts.git_status or {}, {
        -- The rest of my keys (A, ga, gu, gr, gc, gp, gg, the o ordering keys,
        -- z, s and S) are neo-tree's own.
        window = { mappings = { ["Z"] = "expand_all_nodes" } },
      })
      opts.event_handlers = opts.event_handlers or {}
      vim.list_extend(opts.event_handlers, {
        { event = "neo_tree_window_after_open", handler = rebalance },
        { event = "neo_tree_window_after_close", handler = rebalance },
      })
    end,
  },
}
