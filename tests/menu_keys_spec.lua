local h = require("harness")

local feed, drive = h.feed, h.drive

--- A fresh scratch buffer holding `lines`, with the cursor at `pos` ({row, col}).
local function scratch(lines, pos)
  vim.cmd.enew({ bang = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, pos)
end

--- Type `keys` from normal mode and return the cursor ({row, col}) as it was
--- in insert mode, before the final <Esc>.
local function insert_cursor(keys)
  local cursor
  _G.menu_keys_spec_cursor = function()
    cursor = vim.api.nvim_win_get_cursor(0)
  end
  feed(keys .. "<Cmd>lua menu_keys_spec_cursor()<CR><Esc>", "xt")
  return cursor
end

local function menu_open()
  return require("blink.cmp").is_menu_visible()
end

local function menu_closed()
  return not menu_open()
end

-- blink.cmp lazy-loads on InsertEnter and sets up asynchronously; wait, in
-- insert mode, until its mappings exist so every test sees them.
require("lazy").load({ plugins = { "blink.cmp" } })
vim.cmd.enew({ bang = true })
drive("i", {
  function()
    return vim.startswith(vim.fn.maparg("<Tab>", "i", false, true).desc or "", "blink.cmp: ")
  end,
})

-- Editor

h.test("<C-j> and <C-k> move through the menu", function()
  -- Moving through the menu previews each item in the line. Item order isn't
  -- fixed (frecency), so compare previews rather than expect names.
  scratch({ "helloa", "hellob", "" }, { 3, 0 })
  local previews = {}
  local function preview()
    table.insert(previews, vim.api.nvim_get_current_line())
  end
  drive("ihel", { menu_open, "<C-j>", preview, "<C-k>", preview, "<C-j>", preview })
  local second, first = previews[1], previews[2]
  h.eq(true, vim.list_contains({ "helloa", "hellob" }, first), "a completion is previewed: " .. first)
  h.eq(true, first ~= second, "<C-j> and <C-k> select different items: " .. vim.inspect(previews))
  h.eq(second, previews[3], "<C-j> selects the next item again")
end)

h.test("<C-l> with the menu open inserts the selected item", function()
  scratch({ "helloworld", "" }, { 2, 0 })
  local line, still_open
  drive("ihel", {
    menu_open,
    "<C-l>",
    menu_closed,
    function()
      line = vim.api.nvim_get_current_line()
      still_open = menu_open()
    end,
  })
  h.eq("helloworld", line, "accepted line")
  h.eq(false, still_open, "menu closed after accepting")
end)

h.test("<C-h> with the menu open closes it and leaves the text", function()
  scratch({ "helloworld", "" }, { 2, 0 })
  local line, cursor
  drive("ihel", {
    menu_open,
    "<C-h>",
    menu_closed,
    function()
      line = vim.api.nvim_get_current_line()
      cursor = vim.api.nvim_win_get_cursor(0)
    end,
  })
  h.eq("hel", line, "typed text kept")
  h.eq({ 2, 3 }, cursor, "cursor stays after the typed text")
end)

for _, case in ipairs({
  { key = "<C-h>", dir = "left", cursor = { 2, 0 } },
  { key = "<C-l>", dir = "right", cursor = { 2, 2 } },
  { key = "<C-j>", dir = "down", cursor = { 3, 1 } },
  { key = "<C-k>", dir = "up", cursor = { 1, 1 } },
}) do
  h.test(("%s with no menu moves the cursor %s"):format(case.key, case.dir), function()
    scratch({ "abc", "def", "ghi" }, { 2, 1 })
    h.eq(case.cursor, insert_cursor("i" .. case.key))
    h.eq({ "abc", "def", "ghi" }, vim.api.nvim_buf_get_lines(0, 0, -1, false), "no text inserted")
  end)
end

h.test("<C-k> in a buffer with a language server still moves the cursor up", function()
  -- LazyVim maps insert-mode <C-k> to signature help in LSP buffers.
  local file = vim.fn.tempname() .. ".lua"
  vim.fn.writefile({ "local a = 1", "local b = 2" }, file)
  vim.cmd.edit(file)
  -- Insert before the server attaches, as a quick typist would: blink.cmp
  -- maps its keys then, so the LSP keys come after.
  feed("i<Esc>", "xt")
  -- gK comes with the same LSP keys, once the server says it has signature help.
  h.eq(
    true,
    vim.wait(20000, function()
      return vim.fn.maparg("gK", "n", false, true).buffer == 1
    end, 100),
    "lua_ls attached and LazyVim's LSP keys set"
  )
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  h.eq({ 1, 3 }, insert_cursor("i<C-k>"))
end)

h.test("<C-h> and <C-l> moves stay in the current undo step", function()
  scratch({ "abcd" }, { 1, 2 })
  feed("iX<C-h>Y<C-l><C-l>Z<Esc>", "xt")
  h.eq({ "abYXcZd" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  feed("u", "xt")
  h.eq({ "abcd" }, vim.api.nvim_buf_get_lines(0, 0, -1, false), "one undo removes the whole insert")
end)

-- Cmdline

h.test("<C-k> and <C-j> in the cmdline with no menu recall history", function()
  vim.fn.histadd(":", "echo 'menu keys older'")
  vim.fn.histadd(":", "echo 'menu keys newer'")
  local recalled = {}
  local function record()
    table.insert(recalled, vim.fn.getcmdline())
  end
  drive(":", { "<C-k>", record, "<C-k>", record, "<C-j>", record })
  h.eq({ "echo 'menu keys newer'", "echo 'menu keys older'", "echo 'menu keys newer'" }, recalled)
end)

h.test("<C-h> and <C-l> in the cmdline with no menu move the cursor", function()
  local positions = {}
  local function record()
    table.insert(positions, vim.fn.getcmdpos())
  end
  -- A filter cmdline, where the menu doesn't open by itself.
  drive("/", { "abc", record, "<C-h>", record, "<C-h>", record, "<C-l>", record })
  h.eq({ 4, 3, 2, 3 }, positions, "cursor positions (1-based)")
end)

h.test("<C-h> in the cmdline moves before keys queued after it", function()
  -- As in a macro or a mapping: the move must happen before the X is typed.
  local line
  drive("/", {
    "ab<C-h>X",
    function()
      line = vim.fn.getcmdline()
    end,
  })
  h.eq("aXb", line)
end)

h.test("<C-j>, <C-k> and <C-l> move through and accept from the cmdline's menu", function()
  local lines = {}
  local function record()
    table.insert(lines, vim.fn.getcmdline())
  end
  -- Selecting an item inserts it into the cmdline, so compare cmdlines.
  drive(
    ":",
    { "colorscheme ", menu_open, "<C-j>", record, "<C-j>", record, "<C-k>", record, "<C-l>", menu_closed, record }
  )
  local first, second = lines[1], lines[2]
  h.eq(true, vim.startswith(first, "colorscheme ") and #first > #"colorscheme ", "an item is inserted: " .. first)
  h.eq(true, first ~= second, "<C-j> moves to another item: " .. vim.inspect(lines))
  h.eq(first, lines[3], "<C-k> moves back")
  h.eq(first, lines[4], "<C-l> accepts the selected item and closes the menu")
end)

h.test("<C-h> closes the cmdline's menu and leaves the text", function()
  local line
  drive(":", {
    "colorscheme ",
    menu_open,
    "<C-h>",
    menu_closed,
    function()
      line = vim.fn.getcmdline()
    end,
  })
  h.eq("colorscheme ", line)
end)
