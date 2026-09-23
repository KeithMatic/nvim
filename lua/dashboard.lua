-- The Dashboard: the South Park header and a second pane (colour strip, recent
-- files, projects, git status). LazyVim's keys stay as they are. While the
-- Dashboard is current there is no cursor and no statusline.
local icons = require("util.icons")

local M = {}

M.header = [[
 _O_        _____         _<>_          ___
 /     \     |     |      /      \      /  _  \
|==/=\==|    |[/_\]|     |==\==/==|    |  / \  |
|  O O  |    / O O \     |   ><   |    |  |"|  |
 \  V  /    /\  -  /\  ,-\   ()   /-.   \  X  /
 /`---'\     /`---'\   V( `-====-' )V   /`---'\
 O'_:_`O     O'M|M`O   (_____:|_____)   O'_|_`O
 -- --       -- --      ----  ----      -- --
 STAN        KYLE        CARTMAN        KENNY
]]

local colour_strip_cmd = { "colorscript", "-e", "square" }
local colour_strip_shell = table.concat(colour_strip_cmd, " ")
local colour_strip_height = 5

local function warn(problem, fix)
  vim.notify(problem .. "\n" .. fix, vim.log.levels.WARN, { title = "Dashboard colour strip" })
end

-- Whether each open Dashboard's colour strip failed: nil until checked, false
-- while running or once it worked. Sections are resolved again on every redraw
-- (a resize), so this keeps it to one check, and one warning, per Dashboard.
local strip_failed = setmetatable({}, { __mode = "k" })

--- The colour strip: `colorscript`'s output, or empty space of the same size
--- (and one warning) when it's missing or fails.
---@param dashboard snacks.dashboard.Class
local function colour_strip(dashboard)
  local blank = { pane = 2, padding = 1, text = ("\n"):rep(colour_strip_height - 1) }
  if strip_failed[dashboard] == nil then
    if vim.fn.executable(colour_strip_cmd[1]) == 0 then
      strip_failed[dashboard] = true
      warn(
        "`colorscript` isn't on your PATH.",
        "Install shell-color-scripts (https://gitlab.com/dwt1/shell-color-scripts), which provides it."
      )
    else
      -- The terminal section can't report how its command exited, so run it
      -- once more to find out.
      strip_failed[dashboard] = false
      vim.system(colour_strip_cmd, { text = true }, function(result)
        if result.code ~= 0 then
          strip_failed[dashboard] = true
          vim.schedule(function()
            local stderr = vim.trim(result.stderr or "")
            warn(
              ("`%s` exited with code %d%s"):format(
                colour_strip_shell,
                result.code,
                stderr ~= "" and (": " .. stderr) or "."
              ),
              ("Run `%s` in a shell to see what's wrong."):format(colour_strip_shell)
            )
            if vim.api.nvim_buf_is_valid(dashboard.buf) then
              dashboard:update()
            end
          end)
        end
      end)
    end
  end
  if strip_failed[dashboard] then
    return blank
  end
  return {
    pane = 2,
    section = "terminal",
    cmd = colour_strip_shell .. " 2>/dev/null", -- errors go in the warning
    height = colour_strip_height,
    padding = 1,
  }
end

---@type snacks.dashboard.Section[]
M.sections = {
  { section = "header" },
  colour_strip,
  { section = "keys", gap = 1, padding = 1 },
  { pane = 2, icon = icons.ui.History, title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
  { pane = 2, icon = icons.ui.Project, title = "Projects", section = "projects", indent = 2, padding = 1 },
  {
    pane = 2,
    icon = icons.git.Git,
    title = "Git Status",
    section = "terminal",
    enabled = function()
      return Snacks.git.get_root() ~= nil
    end,
    cmd = "git status --short --branch --renames",
    height = 5,
    padding = 1,
    ttl = 5 * 60,
    indent = 3,
  },
  { section = "startup" },
}

-- What the Dashboard replaced while it's current, to put back on leaving it.
local restore ---@type {guicursor: string, laststatus: integer}?

--- Hide the cursor and statusline while the Dashboard is current, and bring
--- them back once it isn't.
function M.sync()
  if vim.bo.filetype == "snacks_dashboard" then
    restore = restore
      or {
        guicursor = vim.go.guicursor,
        -- LazyVim hides the statusline until lualine loads, remembering it here.
        laststatus = vim.o.laststatus ~= 0 and vim.o.laststatus or vim.g.lualine_laststatus or 0,
      }
    -- Set every time: a theme change clears it.
    vim.api.nvim_set_hl(0, "DashboardHiddenCursor", { blend = 100, nocombine = true })
    vim.go.guicursor = "a:DashboardHiddenCursor"
    vim.o.laststatus = 0
  elseif restore then
    -- Reset first, or the terminal can keep the hidden cursor (neovim#21018).
    vim.go.guicursor = "a:"
    vim.cmd.redrawstatus()
    vim.go.guicursor = restore.guicursor
    vim.o.laststatus = restore.laststatus
    restore = nil
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("dashboard", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, { group = group, callback = M.sync })
  -- Snacks opens the Dashboard with autocmds off, so BufEnter doesn't fire.
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "SnacksDashboardOpened", callback = M.sync })
  -- Nor after :bd leaves an empty buffer. Closed fires while the Dashboard is
  -- still current, so wait for it to go.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "SnacksDashboardClosed",
    callback = vim.schedule_wrap(M.sync),
  })
  -- lualine brings the statusline back as it loads (on VeryLazy, after the
  -- Dashboard has opened).
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyLoad",
    callback = function(args)
      if args.data == "lualine.nvim" then
        M.sync()
      end
    end,
  })
end

return M
