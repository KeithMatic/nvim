-- The mode-coloured line number: the cursor's line number in the current
-- mode's Mode colour, as modicator.nvim does. modes.nvim already colours it in
-- insert, visual, delete and copy (through 'winhighlight'); this adds normal
-- and command, and keeps it plain, with no tint or faded line behind it, when
-- it shows alone: while typing, and with the Cursor line off
-- (lua/cursor_line.lua).
local M = {}

local theme = require("theme")

-- modes.nvim's cursor-line gutter groups for the modes that hide the Cursor
-- line: there the number shows alone, so it keeps its colour but not the
-- faded line behind it.
local typing = {}
for _, mode in ipairs({ "Insert", "Replace" }) do
  for _, part in ipairs({ "Nr", "Sign", "Fold" }) do
    table.insert(typing, ("Modes%sCursorLine%s"):format(mode, part))
  end
end

--- Colour CursorLineNr, which modes.nvim leaves in place in normal and
--- command, for whichever of the two is current. Themes with no normal or
--- command colour keep their own.
local function colour_number()
  local color = theme.mode_color(vim.fn.mode():sub(1, 1) == "c" and "command" or "normal")
  if color then
    local hl = theme.get_hl("CursorLineNr")
    hl.fg = color
    vim.api.nvim_set_hl(0, "CursorLineNr", hl)
  end
end

--- Restyle the groups behind the number for the current theme and Cursor
--- line: after modes.nvim, which gives CursorLineNr and CursorLineSign the
--- cursor line's background on a theme change.
function M.refresh()
  theme.gutter_tinted = require("cursor_line").enabled
  theme.apply_tint()
  for _, name in ipairs(typing) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    hl.bg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
  colour_number()
end

--- Call after modes.nvim's setup, so its hook, which redefines its groups on a
--- theme change, runs before this one.
function M.setup()
  local group = vim.api.nvim_create_augroup("line_number", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.refresh })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = { "*:c*", "c*:*" },
    callback = function()
      colour_number()
      -- The command line doesn't redraw the window on its own.
      vim.cmd.redraw()
    end,
  })
  M.refresh()
end

return M
