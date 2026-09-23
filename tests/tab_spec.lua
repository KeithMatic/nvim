local h = require("harness")

local function feed(keys, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), mode, false)
end

--- A fresh scratch buffer holding `lines`, with the cursor at `pos` ({row, col}).
local function scratch(lines, pos)
  vim.cmd.enew({ bang = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, pos)
end

--- Type `keys` from normal mode and return the buffer lines and the cursor
--- ({row, col}) as they were in insert mode, before the final <Esc>.
local function type_keys(keys)
  local cursor
  _G.tab_spec_cursor = function()
    cursor = vim.api.nvim_win_get_cursor(0)
  end
  feed(keys .. "<Cmd>lua tab_spec_cursor()<CR><Esc>", "xt")
  return vim.api.nvim_buf_get_lines(0, 0, -1, false), cursor
end

--- Enter insert mode with `keys` and stay there while `steps` run one after
--- another from a timer, so asynchronous things (the completion menu) can
--- happen. A string step is typed; a function step is polled until it returns
--- something other than false. Insert mode is left once every step is done.
local function drive(keys, steps)
  local i, err = 1, nil
  local deadline = vim.uv.now() + 5000
  local timer = assert(vim.uv.new_timer())
  local function stop()
    timer:stop()
    timer:close()
  end
  local function finish()
    stop()
    feed("<Esc>", "t")
  end
  timer:start(
    50,
    50,
    vim.schedule_wrap(function()
      if timer:is_closing() then
        return
      end
      local step = steps[i]
      if step == nil then
        return finish()
      elseif type(step) == "string" then
        feed(step, "t")
        i = i + 1
      else
        local ok, ret = pcall(step)
        if not ok or vim.uv.now() > deadline then
          err = ok and ("step %d timed out"):format(i) or ret
          return finish()
        elseif ret ~= false then
          i = i + 1
        end
      end
    end)
  )
  feed(keys, "x!")
  if not timer:is_closing() then -- insert mode ended early (e.g. into select mode)
    stop()
    err = err or ("insert mode ended before step %d"):format(i)
  end
  if err then
    error(err, 2)
  end
end

local function menu_open()
  return require("blink.cmp").is_menu_visible()
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

-- The one test that looks at mappings rather than behaviour: "no other plugin
-- maps <Tab>" is a claim about mappings.
h.test("blink.cmp is the only plugin mapping insert-mode <Tab>", function()
  scratch({ "" }, { 1, 0 })
  local maps
  drive("i", {
    function()
      maps = {
        buffer = vim.fn.maparg("<Tab>", "i", false, true),
        global = vim.tbl_filter(function(m)
          return m.lhs == "<Tab>"
        end, vim.api.nvim_get_keymap("i")),
      }
    end,
  })
  h.eq(
    true,
    vim.startswith(maps.buffer.desc or "", "blink.cmp: "),
    "insert <Tab> is blink's: " .. vim.inspect(maps.buffer)
  )
  -- Only Neovim's own default mapping may sit underneath (blink falls back to it).
  for _, m in ipairs(maps.global) do
    local source = m.callback and debug.getinfo(m.callback, "S").source or m.rhs
    h.eq(true, vim.startswith(source, "@vim/"), "global insert <Tab> from " .. tostring(source))
  end
end)

h.test("<Tab> with the menu open accepts the selected item", function()
  scratch({ "helloworld", "" }, { 2, 0 })
  local line, still_open
  drive("ihel", {
    menu_open,
    "<Tab>",
    function()
      line = vim.api.nvim_get_current_line()
      still_open = menu_open()
    end,
  })
  h.eq("helloworld", line, "accepted line")
  h.eq(false, still_open, "menu closed after accepting")
end)

h.test("<Enter> with the menu open inserts a newline and accepts nothing", function()
  scratch({ "helloworld", "" }, { 2, 0 })
  local lines
  drive("ihel", {
    menu_open,
    "<CR>",
    function()
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    end,
  })
  h.eq({ "helloworld", "hel", "" }, lines)
end)

h.test("<C-n>, <C-p> and the arrow keys move through the menu", function()
  -- Moving through the menu previews each item in the line. Item order isn't
  -- fixed (frecency), so compare previews rather than expect names.
  scratch({ "helloa", "hellob", "" }, { 3, 0 })
  local previews = {}
  local function preview()
    table.insert(previews, vim.api.nvim_get_current_line())
  end
  drive("ihel", { menu_open, "<C-n>", preview, "<C-p>", preview, "<Down>", preview, "<Up>", preview })
  local second, first = previews[1], previews[2]
  h.eq(true, vim.list_contains({ "helloa", "hellob" }, first), "a completion is previewed: " .. first)
  h.eq(true, first ~= second, "<C-n> and <C-p> select different items: " .. vim.inspect(previews))
  h.eq({ second, first, second, first }, previews, "<Down>/<Up> move like <C-n>/<C-p>")
end)

h.test("<Tab> accepts a completion rather than tabbing out", function()
  scratch({ "helloworld", ")" }, { 2, 0 })
  local line
  drive("ihel", {
    menu_open,
    "<Tab>",
    function()
      line = vim.api.nvim_get_current_line()
    end,
  })
  h.eq("helloworld)", line)
end)

h.test("<Tab> jumps to the next snippet placeholder rather than tabbing out", function()
  scratch({ "" }, { 1, 0 })
  local line
  drive("i<Cmd>lua vim.snippet.expand('f($1) + $2')<CR>", {
    "<Tab>",
    "X",
    function()
      line = vim.api.nvim_get_current_line()
    end,
  })
  h.eq("f() + X", line)
end)

for _, closer in ipairs({ ")", "]", "}", '"', "'", "`" }) do
  h.test("<Tab> before " .. closer .. " moves past it without inserting text", function()
    local line = "call(x" .. closer .. ");"
    scratch({ line }, { 1, 6 })
    local lines, cursor = type_keys("i<Tab>")
    h.eq({ line }, lines)
    h.eq({ 1, 7 }, cursor, "cursor just past the " .. closer)
  end)
end

h.test("<Tab> in plain text inserts indentation", function()
  scratch({ "abc" }, { 1, 0 })
  local lines = type_keys("i<Tab>")
  h.eq(true, lines[1]:match("^%s+abc$") ~= nil, "indented: " .. vim.inspect(lines[1]))
end)

h.test("<Tab> before a non-closer inserts indentation", function()
  scratch({ "a(b)" }, { 1, 2 })
  local lines = type_keys("i<Tab>")
  h.eq(true, lines[1]:match("^a%(%s+b%)$") ~= nil, "indented: " .. vim.inspect(lines[1]))
end)

h.test("<Tab> inside a snippet jumps to the next placeholder", function()
  scratch({ "" }, { 1, 0 })
  -- Empty placeholders, so the snippet stays in insert mode (no select mode).
  -- The jump happens on the next event-loop tick, so drive rather than type_keys.
  local lines, cursor
  drive("i<Cmd>lua vim.snippet.expand('f($1, $2)')<CR>", {
    "<Tab>",
    "X",
    function()
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      cursor = vim.api.nvim_win_get_cursor(0)
    end,
  })
  h.eq({ "f(, X)" }, lines)
  h.eq({ 1, 5 }, cursor, "cursor after X, at the second placeholder")
end)
