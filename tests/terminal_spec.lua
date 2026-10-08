local h = require("harness")
local terminal = require("terminal")

-- The Terminal manager (floaterm): one float of named terminals beside the
-- Terminal list, on <C-/>, looking like every other float, and only ever
-- Hidden by its keys, never discarded. See docs/floaterm-design.md.

h.attach_ui(160, 40)

-- A plain shell, not the login one with its rc files: quick to start, and
-- ready for input at once. floaterm reads it when it loads.
vim.o.shell = "/bin/sh"

-- A project with a nested folder holding a file, started in its root.
local project = vim.fn.tempname()
vim.fn.mkdir(project .. "/src", "p")
project = assert(vim.uv.fs_realpath(project))
vim.fn.writefile({}, project .. "/src/main.py")
vim.fn.mkdir(project .. "/.git")
vim.fn.chdir(project)
vim.cmd.edit(project .. "/src/main.py")

local function wait_for(what, ok)
  h.eq(true, vim.wait(5000, ok, 20), what)
end

local function state()
  return require("floaterm.state")
end

local function wait_shown()
  wait_for("the Terminal manager shown", terminal.shown)
end

local function wait_hidden()
  wait_for("the Terminal manager hidden", function()
    return not terminal.shown()
  end)
end

--- The terminals' names, in the Terminal list's order.
local function names()
  return vim.tbl_map(function(term)
    return term.name
  end, state().terminals or {})
end

--- Hide the Terminal manager if it's shown, back in normal mode.
local function hide()
  if terminal.shown() then
    terminal.toggle()
  end
  vim.cmd.stopinsert()
  wait_hidden()
  -- floaterm handles a closed window in a scheduled callback, which deletes
  -- the terminal if the manager is shown by then. vim.wait returns at once
  -- when its condition already holds, running nothing, so let the loop turn
  -- while it's hidden, as it does between key presses.
  vim.wait(50, function()
    return false
  end)
end

local rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }

h.test("floaterm doesn't load at startup", function()
  h.eq(nil, package.loaded["floaterm"], "floaterm loaded")
  h.eq(nil, package.loaded["volt"], "volt loaded")
end)

h.test("<C-/> (and <C-_>) toggle the Terminal manager in normal and terminal mode", function()
  for _, mode in ipairs({ "n", "t" }) do
    for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
      local desc = vim.fn.maparg(lhs, mode, false, true).desc
      h.eq(
        true,
        desc == "Terminal Manager" or desc == "which_key_ignore",
        lhs .. " in mode " .. mode .. ": " .. tostring(desc)
      )
    end
  end
  h.feed("<C-/>", "mx")
  wait_shown()
end)

h.test("it starts with one terminal named after the project folder", function()
  h.eq({ vim.fs.basename(project) }, names(), "terminals")
end)

h.test("its three windows look like every other float: rounded, NormalFloat, FloatBorder", function()
  local floaterm = state()
  for _, name in ipairs({ "sidewin", "win", "barwin" }) do
    h.eq(rounded, vim.api.nvim_win_get_config(floaterm[name]).border, name .. " border")
  end
  for group, float in pairs(terminal.float_colors) do
    -- Neovim adds StatusLine:StatusLineTerm to a terminal's window, so look for ours among them.
    for _, name in ipairs({ "win", "barwin" }) do
      local winhl = vim.wo[floaterm[name]].winhighlight
      local pair = group .. ":" .. float
      h.eq(true, vim.list_contains(vim.split(winhl, ","), pair), name .. " winhighlight has " .. pair .. ": " .. winhl)
    end
    -- The Terminal list draws through its own highlight namespace. (Reading a
    -- namespace with `link = false` comes back empty, so read it as set.)
    h.eq(
      vim.api.nvim_get_hl(0, { name = float, link = false }),
      vim.api.nvim_get_hl(floaterm.ns, { name = group }),
      "Terminal list " .. group
    )
  end
end)

h.test("it takes 85% of the editor's width and 80% of its height", function()
  h.eq(math.floor(vim.o.lines * 0.8), vim.api.nvim_win_get_height(state().sidewin), "height")
  h.eq(math.floor(vim.o.columns * 0.85), state().w, "width")
end)

h.test("<Esc><Esc> in a terminal goes to normal mode; one <Esc> stays in the shell", function()
  -- Fed keys can't stay in terminal mode headless, so call the mapping as a key press would.
  local esc = vim.api.nvim_buf_call(state().buf, function()
    return vim.fn.maparg("<Esc>", "t", false, true)
  end)
  h.eq(1, esc.expr, "<Esc> is an expression mapping")
  h.eq("<Esc>", esc.callback(), "a first <Esc>")
  h.eq("<C-\\><C-n>", esc.callback(), "a second <Esc> straight after")
  h.eq("<Esc>", esc.callback(), "a third starts over")
  vim.wait(250, function()
    return false
  end)
  h.eq("<Esc>", esc.callback(), "an <Esc> after a pause")
end)

h.test("q in a terminal Hides the Terminal manager, and the terminal survives", function()
  local buf = state().buf
  local job = vim.b[buf].terminal_job_id
  vim.api.nvim_set_current_win(state().win)
  vim.cmd.stopinsert()
  h.feed("q", "mx")
  wait_hidden()
  h.eq({ vim.fs.basename(project) }, names(), "terminals after q")
  h.eq(true, vim.fn.jobwait({ job }, 0)[1] == -1, "the shell still running")
  h.feed("<C-/>", "mx")
  wait_shown()
  h.eq(buf, vim.api.nvim_win_get_buf(state().win), "the same terminal shown")
end)

h.test("<Esc> in the Terminal list Hides it, even after a terminal was added", function()
  -- Showing a new terminal re-installs volt's discarding q/<Esc> on the list.
  require("floaterm.api").new_term({ name = "second" })
  wait_for("two terminals", function()
    return #names() == 2
  end)
  vim.cmd.stopinsert()
  vim.api.nvim_set_current_win(state().sidewin)
  h.feed("<Esc>", "mx")
  wait_hidden()
  h.eq(2, #names(), "terminals after <Esc>")
end)

-- Each key, the folder its terminal starts in, and that folder's name.
for _, case in ipairs({
  { key = "ft", where = "the project root", dir = "", name = vim.fs.basename(project) },
  { key = "fT", where = "the current file's folder", dir = "/src", name = "src" },
}) do
  h.test(("<leader>%s adds a terminal at %s, named after it"):format(case.key, case.where), function()
    hide()
    vim.cmd.edit(project .. "/src/main.py")
    local before = #names()
    h.feed("<leader>" .. case.key, "mx")
    wait_shown()
    local added = state().terminals[before + 1]
    h.eq(case.name, added and added.name, "name")
    h.eq("cd " .. vim.fn.shellescape(project .. case.dir), added and added.cmd, "cmd")
    h.eq(added and added.buf, state().buf, "the new terminal shown")
  end)
end

h.test("exiting a <leader>fT terminal's shell takes it out of the Terminal list", function()
  -- The <leader>fT test left its terminal shown.
  local exiting = state().buf
  local before = #names()
  vim.fn.chansend(vim.b[exiting].terminal_job_id, "exit\r")
  h.eq(
    true,
    vim.wait(10000, function()
      return #names() == before - 1
    end, 20),
    "the terminal taken out of the list"
  )
  h.eq(false, vim.api.nvim_buf_is_valid(exiting), "its buffer deleted")
  h.eq(true, terminal.shown(), "the Terminal manager still shown")
  h.eq(state().buf, vim.api.nvim_win_get_buf(state().win), "another terminal shown")
end)

h.test("nothing errored", function()
  hide()
  h.eq({}, h.errors(), "errors")
end)
