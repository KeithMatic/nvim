-- The picker's icons (Snacks): the Icon set's prompt glyph in the search bar,
-- and its pointer on the list's cursor row, drawn in a 'statuscolumn' of the
-- list's own, as Snacks draws the prompt in the search bar's.
local M = {}

local icons = require("util.icons")

M.prompt = icons.misc.prompt_prefix
local pointer = icons.misc.selection_caret
local blank = (" "):rep(vim.api.nvim_strwidth(pointer))

--- The list's 'statuscolumn': the pointer on the cursor row's first screen
--- line, blank on the rest. It follows the cursor because Snacks turns
--- 'cursorline' on, which redraws the old and new cursor rows on each move.
---@return string
function M.statuscolumn()
  if vim.v.relnum ~= 0 or vim.v.virtnum ~= 0 then
    return blank
  end
  -- In the cursor line's colours: Snacks maps CursorLine to its own group
  -- while the picker has focus.
  local winhighlight = vim.wo[vim.g.statusline_winid].winhighlight
  local group = winhighlight:match("%f[%w]CursorLine:([%w_]+)") or "CursorLine"
  return ("%%#%s#%s%%*"):format(group, pointer)
end

return M
