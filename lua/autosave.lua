-- Autosave: a file with unsaved changes is saved when you leave Insert mode,
-- switch to another file, or switch to another app. Only real files on disk:
-- not scratch, help or terminal buffers, nor read-only ones. Saving runs the
-- usual write hooks, so format-on-save still applies.
local M = {}

---@param buf integer
local function savable(buf)
  local bo = vim.bo[buf]
  local name = vim.api.nvim_buf_get_name(buf)
  return bo.modified
    and bo.buftype == ""
    and bo.modifiable
    and not bo.readonly
    and name ~= ""
    and vim.fn.isdirectory(vim.fn.fnamemodify(name, ":h")) == 1
end

---@param buf integer
local function save(buf)
  if vim.api.nvim_buf_is_valid(buf) and savable(buf) then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent! lockmarks update")
    end)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("autosave", { clear = true })
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = group,
    callback = function(ev)
      -- Mid-snippet, leaving Insert only moves on to the next placeholder.
      if ev.event == "InsertLeave" and vim.snippet.active() then
        return
      end
      save(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        save(buf)
      end
    end,
  })
end

return M
