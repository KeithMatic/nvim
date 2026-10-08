local h = require("harness")

-- The cheat sheet: the README, every keymap and feature, in a float over
-- whatever is open, from anywhere with <leader>sK; q closes it.

h.attach_ui(160, 40)

local readme = vim.fn.stdpath("config") .. "/README.md"

h.test("<leader>sK is the cheat sheet", function()
  h.eq("Keymaps & Features", vim.fn.maparg(vim.g.mapleader .. "sK", "n", false, true).desc, "<leader>sK")
end)

h.test("<leader>sK opens the README's text in a float over the file, read-only", function()
  h.open("lua")
  local file_win, file_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  h.feed("<leader>sK", "mx")
  local win = vim.api.nvim_get_current_win()
  h.eq(true, win ~= file_win, "a window of its own")
  h.eq(true, vim.api.nvim_win_get_config(win).relative ~= "", "a float")
  h.eq(vim.fn.readfile(readme), vim.api.nvim_buf_get_lines(0, 0, -1, false), "showing the README")
  h.eq("nofile", vim.bo.buftype, "a scratch buffer, not the file")
  h.eq("markdown", vim.bo.filetype, "filetype")
  h.eq(false, vim.bo.modifiable, "not modifiable")
  h.eq({ "╭", "─", "╮", "│", "╯", "─", "╰", "│" }, vim.api.nvim_win_get_config(win).border, "border")
  h.eq(file_buf, vim.api.nvim_win_get_buf(file_win), "the file still in its window")
end)

h.test("q closes it, back in the file", function()
  local float = vim.api.nvim_get_current_win()
  h.feed("q", "mx")
  h.eq(
    true,
    vim.wait(1000, function()
      return not vim.api.nvim_win_is_valid(float)
    end, 20),
    "the float closed"
  )
  h.eq("lua", vim.bo.filetype, "back in the file")
end)

h.test("nothing errored", function()
  -- Neovim's markdown ftplugin undoes itself with `sil! nunmap <buffer> [[`,
  -- which still leaves E31 in v:errmsg; opening any Markdown file does it.
  local errors = vim.tbl_filter(function(err)
    return not err:find("E31: No such mapping", 1, true)
  end, h.errors())
  h.eq({}, errors, "errors")
end)
