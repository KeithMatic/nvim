-- The Cursor line: the tinted line under the cursor, in file windows only.
-- Menus and panels (the picker, the Explorer, the Database drawer) keep their
-- own selected line whatever this says. Hidden while typing; <leader>uH turns
-- it off and on (lua/persistent_toggles.lua).
local M = {}

M.enabled = true

--- Whether `win` shows a file, rather than a menu, a panel or a float.
local function is_editor(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.api.nvim_win_get_config(win).relative == ""
end

---@param win integer
---@param typing boolean
local function apply(win, typing)
  if is_editor(win) then
    vim.wo[win].cursorline = M.enabled and not typing
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType", "InsertEnter", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("cursor_line", { clear = true }),
    callback = function(ev)
      -- InsertEnter runs just before the mode changes, so mode() can't tell yet.
      local typing = ev.event == "InsertEnter" or (ev.event ~= "InsertLeave" and vim.fn.mode():find("^[iR]") ~= nil)
      apply(vim.api.nvim_get_current_win(), typing)
    end,
  })
end

function M.toggle()
  return Snacks.toggle({
    name = "Cursor Line",
    get = function()
      return M.enabled
    end,
    set = function(state)
      M.enabled = state
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        apply(win, false)
      end
    end,
  })
end

return M
