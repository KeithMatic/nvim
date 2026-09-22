local h = require("harness")

--- Open a scratch buffer of filetype `ft` holding `line`, put the cursor in
--- insert mode before byte `col` (0-based), type `keys`, and return the line
--- and the insert-mode cursor column (0-based) once typing is done.
local function type_in(ft, line, col, keys)
  vim.cmd.enew({ bang = true })
  vim.bo.filetype = ft
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
  vim.api.nvim_win_set_cursor(0, { 1, col })
  local cursor
  _G.semicolon_spec_cursor = function()
    cursor = vim.api.nvim_win_get_cursor(0)[2]
  end
  local feed = "i" .. keys .. "<Cmd>lua semicolon_spec_cursor()<CR><Esc>"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(feed, true, false, true), "xt", false)
  return vim.api.nvim_get_current_line(), cursor
end

h.test("TS: ; typed mid-line lands at end of line, cursor after it", function()
  local line, cursor = type_in("typescript", "const x = foo(bar)", 14, ";")
  h.eq("const x = foo(bar);", line)
  h.eq(#line, cursor, "cursor at end of line")
end)

h.test("TS: a line already ending in ; is not doubled", function()
  local line, cursor = type_in("typescript", "const x = foo(bar);", 14, ";")
  h.eq("const x = foo(bar);", line)
  h.eq(#line, cursor, "cursor at end of line")
end)

h.test("TS: trailing whitespace is ignored: ; goes after the code, never doubled", function()
  local line, cursor = type_in("typescript", "foo(bar)  ", 4, ";")
  h.eq("foo(bar);  ", line)
  h.eq(9, cursor, "cursor after the ;")
  h.eq("foo(bar);  ", (type_in("typescript", "foo(bar);  ", 4, ";")))
  h.eq("foo(;bar)  ", (type_in("typescript", "foo(bar)  ", 4, ";;")))
end)

h.test("TS: ; at the end of an already-terminated line is not doubled", function()
  local line, cursor = type_in("typescript", "foo();", 0, "<End>;")
  h.eq("foo();", line)
  h.eq(#line, cursor, "cursor at end of line")
end)

h.test("TS: ; typed in trailing whitespace goes after the code", function()
  local line, cursor = type_in("typescript", "foo()    ", 7, ";")
  h.eq("foo();    ", line)
  h.eq(6, cursor, "cursor after the ;")
end)

h.test("TS: ; on a blank indented line is inserted at the cursor", function()
  local line, cursor = type_in("typescript", "    ", 0, "<End>;")
  h.eq("    ;", line)
  h.eq(5, cursor, "cursor after the ;")
end)

h.test("TS: ; is literal again once the filetype leaves the allow-list", function()
  vim.cmd.enew({ bang = true })
  vim.bo.filetype = "typescript"
  local line = type_in("python", "a(b)", 2, ";")
  h.eq("a(;b)", line)
  vim.bo.filetype = "typescript"
  vim.bo.filetype = "python"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a(b)" })
  vim.api.nvim_win_set_cursor(0, { 1, 2 })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i;<Esc>", true, false, true), "xt", false)
  h.eq("a(;b)", vim.api.nvim_get_current_line())
end)

h.test("TS: ; at end of line is inserted normally", function()
  local line, cursor = type_in("typescript", "const x = 1", 11, ";")
  h.eq("const x = 1;", line)
  h.eq(#line, cursor, "cursor at end of line")
end)

h.test("TS: a double ; gives one literal ; at the original position", function()
  local line, cursor = type_in("typescript", "for ()", 5, ";;")
  h.eq("for (;)", line)
  h.eq(6, cursor, "cursor after the literal ;")
end)

h.test("TS: a double ; on an already-terminated line leaves no extra trailing ;", function()
  local line = type_in("typescript", 'const s = "ab";', 12, ";;")
  h.eq('const s = "a;b";', line)
end)

h.test("TS: two double ; build for (;;)", function()
  local line = type_in("typescript", "for ()", 5, ";;;;")
  h.eq("for (;;)", line)
end)

h.test("TS: ; after other typing is smart again", function()
  local line = type_in("typescript", "foo()", 4, ";;x;")
  h.eq("foo(;x);", line)
end)

for _, ft in ipairs({ "javascript", "typescriptreact", "c", "cpp", "rust", "css", "scss" }) do
  h.test(ft .. ": ; goes to end of line", function()
    h.eq("a(b);", (type_in(ft, "a(b)", 2, ";")))
  end)
end

for _, ft in ipairs({ "python", "lua", "go", "markdown" }) do
  h.test(ft .. ": ; is inserted literally at the cursor", function()
    local line, cursor = type_in(ft, "foo(bar)", 4, ";")
    h.eq("foo(;bar)", line)
    h.eq(5, cursor, "cursor after the ;")
  end)
end
