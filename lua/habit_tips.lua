-- Habit tips (tobira.nvim): the better command for something just done the
-- long way. tobira has no options for any of this, so it's done by wrapping
-- its parts:
--   1. quietening silences the tips it would show on its own, never the one
--      asked for (`:Tobira`), and keeps the counting going;
--   2. while a Layer is active there are no tips at all, and its keys aren't
--      counted: they're the Layer's actions, not Vim commands;
--   3. its colours, which it sets again every time it draws, get the theme's
--      accent for headings, bold keys, an italic reason line, the theme's
--      green when a tip is taken up, and borders with no background;
--   4. its notice for each key it leaves out of the tips, because the key is
--      mapped to something else, goes to the notification history only.
local M = {}

local theme = require("theme")
local layer = require("layer")

-- Whether tobira shows tips on its own: the Habit tips toggle.
M.enabled = true

-- The tip borders' groups, one per category (tobira's ui/float.lua). The diff
-- one links to DiffChange, a solid block that would paint a band round the
-- glass, so it takes the changed-text colour instead.
local borders = {
  TobiraSuggestMotion = "TobiraSuggestMotion",
  TobiraSuggestEdit = "TobiraSuggestEdit",
  TobiraSuggestSearch = "TobiraSuggestSearch",
  TobiraSuggestWindow = "TobiraSuggestWindow",
  TobiraSuggestFold = "TobiraSuggestFold",
  TobiraSuggestMark = "TobiraSuggestMark",
  TobiraSuggestMacro = "TobiraSuggestMacro",
  TobiraSuggestDiff = "Changed",
  TobiraSuggestEx = "TobiraSuggestEx",
  TobiraSuggestTerminal = "TobiraSuggestTerminal",
}

--- `name`'s colours with `changes` on top, links followed.
local function restyle(name, from, changes)
  vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", theme.get_hl(from), changes))
end

--- The finishing touches over tobira's own links. A theme with no Mode
--- colours keeps tobira's colour and gets only the style.
local function polish()
  local accent = theme.mode_color("normal")
  local green = theme.mode_color("insert")
  for _, name in ipairs({ "TobiraH1", "TobiraGuideSection" }) do
    restyle(name, "Title", { fg = accent, bold = true })
  end
  for _, name in ipairs({ "TobiraSuggestKey", "TobiraGuideKey" }) do
    restyle(name, "Special", { bold = true })
  end
  restyle("TobiraSuggestReason", "Comment", { italic = true })
  restyle("TobiraCelebrate", "DiagnosticOk", { fg = green })
  for name, from in pairs(borders) do
    restyle(name, from, { bg = "NONE" })
  end
end

--- Whether Snacks' notifier should show `notif`: anything but tobira's notice
--- that a key is mapped to something else, so it's left out of the tips. The
--- notice is matched against tobira's own wording, in whichever language it
--- speaks.
---@param notif snacks.notifier.Notif
---@return boolean
function M.show_notice(notif)
  -- Not loaded means no notice yet, and nothing to load tobira for.
  if notif.level ~= "debug" or not package.loaded["tobira.core.config"] then
    return true
  end
  local wording = require("tobira.i18n").load().notifications.remap_detected
  local notice = "^" .. vim.pesc(wording):gsub("%%%%s", ".-")
  return not notif.msg:find(notice)
end

--- Wrap tobira's setup, before it runs and before anything draws.
---@param opts table tobira's options
function M.setup(opts)
  -- Every float and panel calls the highlight setup each time it draws, and
  -- keeps its own reference to it, taken when the panel's module first loads:
  -- so it's wrapped before any of them can load.
  local hls = require("tobira.ui.hls")
  local set_links = hls.setup
  hls.setup = function()
    set_links()
    polish()
  end

  -- tobira counts keys through vim.on_key callbacks it registers while it
  -- sets up, and there's no way to reach a callback once it's registered, so
  -- vim.on_key is swapped out just for that moment: those callbacks skip
  -- every key while a Layer is active. Callbacks it registers later (watching
  -- whether a tip is taken up) are left alone.
  local on_key = vim.on_key
  vim.on_key = function(fn, ns, ...)
    return on_key(fn and function(...)
      if not layer.active() then
        return fn(...)
      end
    end, ns, ...)
  end
  local ok, err = pcall(require("tobira").setup, opts)
  vim.on_key = on_key
  if not ok then
    error(err)
  end

  -- Both kinds of tip it shows on its own, after a pattern and when idle, go
  -- through `show`; one asked for goes through `manual`.
  local suggest = require("tobira.core.suggest")
  local show, manual = suggest.show, suggest.manual
  suggest.show = function(...)
    if M.enabled and not layer.active() then
      return show(...)
    end
  end
  suggest.manual = function(...)
    if not layer.active() then
      return manual(...)
    end
  end

  require("toggle_state")
    .persist(
      "ui.habit_tips",
      Snacks.toggle({
        name = "Habit tips",
        get = function()
          return M.enabled
        end,
        set = function(state)
          M.enabled = state
        end,
      }),
      { default = true }
    )
    :map("<leader>ut")
end

return M
