-- Tab out of closers (VS Code taboutx parity), one link in the blink.cmp <Tab>
-- chain (see plugins/editing.lua).
local M = {}

local closers = { [")"] = true, ["]"] = true, ["}"] = true, ['"'] = true, ["'"] = true, ["`"] = true }

--- In insert mode, when the character under the cursor is a closer, returns
--- the keys that move past it; otherwise nil, so the Tab chain falls through.
--- Keys rather than a cursor move, since blink.cmp runs this from an <expr>
--- mapping (which restores the cursor). <C-g>U keeps the move in the current
--- undo step and dot-repeat. Insert mode only: blink also runs the chain in
--- select mode, where returned keys are dropped.
---@return string?
function M.tabout()
  if vim.fn.mode() ~= "i" then
    return
  end
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if closers[vim.api.nvim_get_current_line():sub(col + 1, col + 1)] then
    return vim.keycode("<C-g>U<Right>")
  end
end

return M
