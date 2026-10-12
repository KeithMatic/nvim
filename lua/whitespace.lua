-- d.: shrink the run of spaces (or tabs) under the cursor to one space. An
-- operator, so `.` repeats it on the next run.
local M = {}

--- Shrink the run of whitespace under the cursor to one space; on anything
--- else, or a single space already, change nothing.
function M.shrink()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local from, to = col + 1, col + 1
  if not line:sub(from, from):match("%s") then
    return
  end
  while from > 1 and line:sub(from - 1, from - 1):match("%s") do
    from = from - 1
  end
  while to < #line and line:sub(to + 1, to + 1):match("%s") do
    to = to + 1
  end
  if from == to and line:sub(from, from) == " " then
    return
  end
  vim.api.nvim_buf_set_text(0, row - 1, from - 1, row - 1, to, { " " })
  vim.api.nvim_win_set_cursor(0, { row, from - 1 })
end

--- The d. mapping's expr: `shrink` as the operator, over the character under
--- the cursor, so `.` runs it again where the cursor is then.
---@return string
function M.shrink_operator()
  vim.o.operatorfunc = "v:lua.require'whitespace'.shrink"
  return "g@l"
end

return M
