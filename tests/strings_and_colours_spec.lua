local h = require("harness")

local function feed(keys, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), mode, false)
end

local scratch_dir = vim.fn.tempname()
vim.fn.mkdir(scratch_dir, "p")

--- Open `file` in a scratch directory holding `lines`, with the cursor at `pos`
--- ({row, col}), and return its buffer. A real file, so filetype and
--- file-triggered plugins load as they would for the user.
local function open(file, lines, pos)
  local path = scratch_dir .. "/" .. file
  vim.fn.writefile(lines, path)
  vim.cmd.edit({ vim.fn.fnameescape(path), bang = true })
  if pos then
    vim.api.nvim_win_set_cursor(0, pos)
  end
  return vim.api.nvim_get_current_buf()
end

--- The current line once it equals `want`, or as it is after 2s.
local function line_becomes(want)
  vim.wait(2000, function()
    return vim.api.nvim_get_current_line() == want
  end, 50)
  return vim.api.nvim_get_current_line()
end

h.test("Python: typing a {…} placeholder in a normal string makes it an f-string", function()
  open("strings.py", { 'greeting = "hello "' }, { 1, 18 })
  feed("i{name}<Esc>", "xt")
  h.eq('greeting = f"hello {name}"', line_becomes('greeting = f"hello {name}"'))
end)

for _, case in ipairs({
  { file = "strings.ts", quote = '"' },
  { file = "strings.ts", quote = "'" },
  { file = "strings.js", quote = '"' },
}) do
  h.test(("%s: typing ${ in a %s-quoted string makes it a template literal"):format(case.file, case.quote), function()
    local line = "const greeting = " .. case.quote .. "hello " .. case.quote .. ";"
    open(case.file, { line }, { 1, #line - 2 })
    feed("i${name}<Esc>", "xt")
    h.eq("const greeting = `hello ${name}`;", line_becomes("const greeting = `hello ${name}`;"))
  end)
end

h.test("Lua: typing a %s placeholder leaves the string alone", function()
  open("strings.lua", { 'local greeting = "hello "' }, { 1, 24 })
  feed("i%s<Esc>", "xt")
  vim.wait(300, function()
    return false
  end)
  h.eq('local greeting = "hello %s"', vim.api.nvim_get_current_line())
end)

h.test("the mini-hipatterns extra is enabled, from config rather than the extras UI", function()
  local extra = vim.iter(LazyVim.extras.get()):find(function(e)
    return e.name == "util.mini-hipatterns"
  end)
  h.eq(true, extra ~= nil and extra.enabled, "util.mini-hipatterns enabled")
  h.eq(false, extra and extra.managed, "enabled by an explicit import, not the extras UI")
end)

--- The background colour (as a number) of the highlight over `buf` at
--- ({row, col}, 0-based), once one appears there, else nil after 2s.
local function background_at(buf, row, col)
  local bg
  vim.wait(2000, function()
    for _, mark in ipairs(vim.inspect_pos(buf, row, col).extmarks) do
      local group = mark.opts.hl_group
      bg = group and vim.api.nvim_get_hl(0, { name = group, link = false }).bg
      if bg then
        return true
      end
    end
    return false
  end, 50)
  return bg
end

h.test("a hex colour is highlighted with that colour as its background", function()
  local buf = open("colours.lua", { 'local red = "#ff0000"' })
  h.eq(0xff0000, background_at(buf, 0, 14), "background behind #ff0000")
end)

h.test("a Tailwind colour class is highlighted with its colour as its background", function()
  local buf = open("colours.html", { '<div class="bg-red-500"></div>' })
  h.eq(0xef4444, background_at(buf, 0, 13), "background behind bg-red-500")
end)

h.test("file paths complete from the completion engine", function()
  vim.fn.writefile({}, scratch_dir .. "/unique-target.txt")
  open("paths.txt", { "" }, { 1, 0 })
  -- Wait for the menu, accept with <Tab>, then read the line on the next tick.
  local line, accepted
  local timer = assert(vim.uv.new_timer())
  local deadline = vim.uv.now() + 5000
  timer:start(
    50,
    50,
    vim.schedule_wrap(function()
      if timer:is_closing() then
        return
      end
      if accepted or vim.uv.now() > deadline then
        line = vim.api.nvim_get_current_line()
        timer:stop()
        timer:close()
        feed("<Esc>", "t")
      elseif require("blink.cmp").is_menu_visible() then
        accepted = true
        feed("<Tab>", "t")
      end
    end)
  )
  feed("i./uni", "x!")
  h.eq("./unique-target.txt", line)
end)
