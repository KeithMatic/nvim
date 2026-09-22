-- Smart semicolon (VS Code smartsemicolon parity). In C-like filetypes, `;`
-- typed in insert mode goes to the end of the code on the line (never doubling
-- a trailing one) and the cursor follows it. Typing `;` again straight away
-- undoes that and inserts a literal `;` where the cursor was, for `for (;;)`
-- and strings.
local M = {}

local filetypes = {
  "c",
  "cpp",
  "cs",
  "css",
  "dart",
  "java",
  "javascript",
  "javascriptreact",
  "less",
  "rust",
  "scss",
  "typescript",
  "typescriptreact",
}

-- Per buffer, the last smart `;`: the column it was typed at, whether it added
-- a `;` and where it left the cursor. It can only be undone by the very next
-- keystroke, i.e. while the buffer and cursor are exactly as it left them.
---@type table<integer, {row: integer, typed_col: integer, added: boolean, tick: integer, landed_col: integer}>
local undoable = {}

local function insert_semicolon(buf, row, col)
  vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, { ";" })
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })
end

local function semicolon()
  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  local prev = undoable[buf]
  undoable[buf] = nil
  if prev and prev.row == row and prev.landed_col == col and prev.tick == vim.b[buf].changedtick then
    if prev.added then
      vim.api.nvim_buf_set_text(buf, row - 1, col - 1, row - 1, col, {})
    end
    return insert_semicolon(buf, row, prev.typed_col)
  end

  -- Trailing whitespace isn't code: the `;` goes after the last non-blank.
  local code_end = #line:gsub("%s+$", "")
  if code_end == 0 then
    return insert_semicolon(buf, row, col)
  end

  local added = line:sub(code_end, code_end) ~= ";"
  if added then
    insert_semicolon(buf, row, code_end)
  else
    vim.api.nvim_win_set_cursor(0, { row, code_end })
  end
  local landed_col = vim.api.nvim_win_get_cursor(0)[2]
  undoable[buf] = { row = row, typed_col = col, added = added, tick = vim.b[buf].changedtick, landed_col = landed_col }
end

local function attach(buf)
  vim.keymap.set("i", ";", semicolon, { buffer = buf, desc = "Smart semicolon" })
  vim.b[buf].smart_semicolon = true
end

local function detach(buf)
  if vim.b[buf].smart_semicolon then
    vim.keymap.del("i", ";", { buffer = buf })
    vim.b[buf].smart_semicolon = nil
  end
end

local function update(buf)
  if vim.list_contains(filetypes, vim.bo[buf].filetype) then
    attach(buf)
  else
    detach(buf)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("semicolon", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev)
      update(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      undoable[ev.buf] = nil
    end,
  })
  -- Buffers opened before setup (it runs on VeryLazy) missed their FileType event.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      update(buf)
    end
  end
end

return M
