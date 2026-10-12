local h = require("harness")

-- lua/config/keymaps.lua: the keys ported from the AstroNvim mappings.lua, and
-- the Clashes they were resolved against (docs/keymap-port-design.md).

--- A fresh scratch buffer holding `lines`, with the cursor at `pos` ({row, col}).
local function scratch(lines, pos)
  vim.cmd.enew({ bang = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, pos)
end

local function desc(lhs, mode)
  return vim.fn.maparg(lhs, mode, false, true).desc
end

h.test("the existing keys win over the ported duplicates", function()
  h.eq("Prev File", desc("H", "n"), "H: the Buffer sticks")
  h.eq("Next File", desc("L", "n"), "L: the Buffer sticks")
  h.eq("Save File", desc("<C-s>", "n"), "<C-s>: LazyVim's save")
  h.eq("Delete Buffer and Window", desc("<leader>bD", "n"), "<leader>bD: LazyVim's")
  h.eq("Move Down", desc("<M-j>", "i"), "insert <M-j>: LazyVim's move-line")
  h.eq("", vim.fn.maparg("<F2>", "n"), "no <F2>")
  h.eq("", vim.fn.maparg(vim.keycode("<leader>bn"), "n"), "no <leader>bn")
  h.eq("", vim.fn.maparg(vim.keycode("<leader>u1"), "n"), "no <leader>u1")
end)

h.test("<CR> changes the word in a file", function()
  scratch({ "foo bar" }, { 1, 4 })
  h.feed("<CR>baz<Esc>", "xt")
  h.eq({ "foo baz" }, vim.api.nvim_buf_get_lines(0, 0, -1, false), "the word changed")
end)

h.test("<CR> in the quickfix list still jumps to the entry", function()
  scratch({ "one", "two" }, { 1, 0 })
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.setqflist({ { bufnr = buf, lnum = 2, col = 1, text = "two" } })
  vim.cmd.copen()
  h.feed("<CR>", "xt")
  h.eq(buf, vim.api.nvim_get_current_buf(), "in the entry's buffer")
  h.eq(2, vim.api.nvim_win_get_cursor(0)[1], "on the entry's line")
  vim.cmd.cclose()
end)

h.test("n after a ? search still goes down, centred, and stays in Normal mode", function()
  scratch({ "x", "x", "x" }, { 2, 0 })
  h.feed("?x<CR>", "xt")
  h.eq(1, vim.api.nvim_win_get_cursor(0)[1], "? went up")
  h.feed("n", "xt")
  h.eq(2, vim.api.nvim_win_get_cursor(0)[1], "n went down")
  h.eq("n", vim.fn.mode(), "Normal mode")
end)

h.test("visual r replaces every copy of the selection across the file, literally", function()
  scratch({ "a.b x a.b", "axb a.b" }, { 1, 0 })
  h.feed("vllrZ<CR>", "xt")
  h.eq({ "Z x Z", "axb Z" }, vim.api.nvim_buf_get_lines(0, 0, -1, false), "every a.b, not axb")
end)

h.test("d. shrinks the run of spaces under the cursor to one, and leaves anything else alone", function()
  for _, case in ipairs({
    { "a    b", 3, "a b", "a run of spaces" },
    { "a b", 1, "a b", "a single space" },
    { "abc def", 1, "abc def", "a word" },
  }) do
    local line, col, expected, what = unpack(case)
    scratch({ line }, { 1, col })
    h.feed("d.", "xt")
    h.eq({ expected }, vim.api.nvim_buf_get_lines(0, 0, -1, false), what)
  end
end)

h.test("insert <C-a> goes to the line's first non-blank without leaving Insert mode", function()
  scratch({ "    foo bar" }, { 1, 10 })
  local left = 0
  local id = vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      left = left + 1
    end,
  })
  h.feed("a<C-a>X<Esc>", "xt")
  vim.api.nvim_del_autocmd(id)
  h.eq({ "    Xfoo bar" }, vim.api.nvim_buf_get_lines(0, 0, -1, false), "typed at the first non-blank")
  h.eq(1, left, "Insert mode left once, by <Esc>")
end)

h.test("- opens mini.files on the current file's folder", function()
  h.open("lua")
  local file = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0))
  h.feed("-", "xt")
  local state
  h.eq(
    true,
    vim.wait(1000, function()
      state = require("mini.files").get_explorer_state()
      return state ~= nil
    end, 20),
    "mini.files opened"
  )
  h.eq({ vim.fs.dirname(file), file }, state.branch, "the file's folder, the file revealed")
  require("mini.files").close()
end)

h.test("nothing errored", function()
  h.eq({}, h.errors(), "errors")
end)
