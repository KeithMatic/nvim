local h = require("harness")

local header_rows = {
  "STAN        KYLE        CARTMAN        KENNY",
  "/`---'\\     /`---'\\   V( `-====-' )V   /`---'\\",
}

-- Wide enough for both panes side by side.
vim.o.columns = 160
vim.o.lines = 50

-- A project with no git repo, so the Git Status section has nothing to show.
local plain = vim.fn.tempname()
vim.fn.mkdir(plain, "p")
plain = assert(vim.uv.fs_realpath(plain))
local file = plain .. "/notes.txt"
vim.fn.writefile({ "hello" }, file)

local real_path = vim.env.PATH

--- PATH with every directory holding a `colorscript` left out, plus `extra`.
local function path_without_colorscript(extra)
  local dirs = vim.tbl_filter(function(dir)
    return vim.fn.executable(dir .. "/colorscript") == 0
  end, vim.split(real_path, ":", { plain = true }))
  if extra then
    table.insert(dirs, 1, extra)
  end
  return table.concat(dirs, ":")
end

--- A directory holding a fake `colorscript` running `body`.
local function fake_colorscript(body)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile({ "#!/bin/sh", body }, dir .. "/colorscript")
  vim.fn.setfperm(dir .. "/colorscript", "rwxr-xr-x")
  return dir
end

--- Notifications sent (through the notifier) while `fn` runs, and for
--- `settle` ms after, for anything asynchronous.
---@return snacks.notifier.Notif[]
local function notified(fn, settle)
  local before = #Snacks.notifier.get_history()
  fn()
  vim.wait(settle or 300, function()
    return false
  end)
  return vim.list_slice(Snacks.notifier.get_history(), before + 1)
end

--- Close every Dashboard (and, once its scheduled cleanup has run, its
--- terminal windows).
local function close_dashboards()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "snacks_dashboard" and vim.bo[buf].buftype ~= "terminal" then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  vim.wait(50, function()
    return false
  end)
end

--- Open the Dashboard in `cwd`.
---@return snacks.notifier.Notif[] notifications sent meanwhile
local function open_dashboard(cwd, settle)
  close_dashboards()
  vim.fn.chdir(cwd)
  return notified(Snacks.dashboard.open, settle)
end

local function warnings(sent)
  return vim.tbl_filter(function(n)
    return n.level == "warn"
  end, sent)
end

local function dashboard_text()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

--- The floating terminal windows the Dashboard drew its terminal sections in.
local function terminal_wins()
  return vim.tbl_filter(function(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_config(win).relative ~= "" and vim.bo[buf].buftype == "terminal"
  end, vim.api.nvim_list_wins())
end

h.test("the Dashboard shows the South Park header", function()
  vim.env.PATH = path_without_colorscript()
  open_dashboard(plain)
  h.eq("snacks_dashboard", vim.bo.filetype, "the Dashboard is current")
  local text = dashboard_text()
  for _, row in ipairs(header_rows) do
    h.eq(true, require("dashboard").header:find(row, 1, true) ~= nil, "the South Park header has: " .. row)
  end
  -- Every row, as Snacks draws it (centred, so trailing space may go).
  for _, row in ipairs(vim.split(vim.trim(require("dashboard").header), "\n")) do
    h.eq(true, text:find(vim.trim(row), 1, true) ~= nil, "header row shown: " .. row)
  end
end)

--- The Dashboard keys LazyVim alone gives: its core list, changed by the opts
--- functions of its enabled extras (the picker's adds Projects).
local function lazyvim_keys()
  -- A fresh copy of the core list: lazy.nvim merges opts in place, so the one
  -- it loaded already has the extras' changes.
  local core = assert(vim.api.nvim_get_runtime_file("lua/lazyvim/plugins/ui.lua", false)[1])
  local keys
  for _, spec in ipairs(dofile(core)) do
    keys = keys or vim.tbl_get(spec, "opts", "dashboard", "preset", "keys")
  end
  local opts = vim.deepcopy(LazyVim.opts("snacks.nvim"))
  opts.dashboard.preset.keys = assert(keys, "LazyVim's core Dashboard keys")

  -- A plugin's specs, each inheriting (by metatable) from the one before.
  local specs = {}
  local spec = require("lazy.core.config").plugins["snacks.nvim"]
  while spec do
    table.insert(specs, 1, spec)
    local super = getmetatable(spec)
    spec = super and super.__index
  end
  for _, s in ipairs(specs) do
    local fn = rawget(s, "opts")
    if type(fn) == "function" and debug.getinfo(fn, "S").source:find("/lazyvim/", 1, true) then
      opts = fn(s, opts) or opts
    end
  end
  return opts.dashboard.preset.keys
end

h.test("the Dashboard's keys are LazyVim's own", function()
  h.eq(lazyvim_keys(), Snacks.config.dashboard.preset.keys, "Dashboard keys")
end)

h.test("the second pane has recent files and projects, and git status only in a git repo", function()
  vim.env.PATH = path_without_colorscript()
  open_dashboard(plain)
  local text = dashboard_text()
  h.eq(true, text:find("Recent Files", 1, true) ~= nil, "Recent Files shown")
  h.eq(true, text:find("Projects", 1, true) ~= nil, "Projects shown")
  h.eq(false, text:find("Git Status", 1, true) ~= nil, "no Git Status outside a git repo")

  open_dashboard(vim.fn.stdpath("config"))
  h.eq(true, dashboard_text():find("Git Status", 1, true) ~= nil, "Git Status inside a git repo")
end)

h.test("without colorscript, the Dashboard opens with no error and one warning", function()
  vim.env.PATH = path_without_colorscript()
  vim.v.errmsg = ""
  local sent = open_dashboard(plain)
  h.eq("snacks_dashboard", vim.bo.filetype, "the Dashboard is current")
  h.eq({}, h.errors(), "errors")
  local warned = warnings(sent)
  h.eq(1, #warned, "one warning: " .. vim.inspect(sent))
  h.eq(true, warned[1].msg:find("colorscript", 1, true) ~= nil, "the warning names colorscript")

  -- Redrawing (as a resize does) doesn't warn again.
  local again = notified(Snacks.dashboard.update)
  h.eq({}, warnings(again), "no warning on redraw")
end)

h.test("when colorscript fails, its space stays empty and one warning names the problem", function()
  vim.env.PATH = path_without_colorscript(fake_colorscript("echo 'no such script' >&2; exit 3"))
  vim.v.errmsg = ""
  local sent = open_dashboard(plain, 1000)
  h.eq({}, h.errors(), "errors")
  local warned = warnings(sent)
  h.eq(1, #warned, "one warning: " .. vim.inspect(sent))
  h.eq(true, warned[1].msg:find("colorscript", 1, true) ~= nil, "the warning names colorscript")
  h.eq({}, terminal_wins(), "no colour strip drawn")
end)

h.test("with colorscript working, the colour strip is drawn and nothing warns", function()
  vim.env.PATH = path_without_colorscript(fake_colorscript("printf '\\033[31mred\\033[0m\\n'"))
  local sent = open_dashboard(plain, 1000)
  h.eq({}, warnings(sent), "warnings")
  h.eq(1, #terminal_wins(), "the colour strip's terminal")
end)

h.test("no cursor or statusline on the Dashboard; both back after opening a file", function()
  vim.env.PATH = path_without_colorscript(fake_colorscript("true"))
  close_dashboards()
  local guicursor, laststatus = vim.go.guicursor, vim.o.laststatus
  h.eq(3, laststatus, "the global statusline, before the Dashboard")

  open_dashboard(plain)
  h.eq("snacks_dashboard", vim.bo.filetype, "the Dashboard is current")
  h.eq(0, vim.o.laststatus, "laststatus on the Dashboard")
  for _, part in ipairs(vim.split(vim.go.guicursor, ",")) do
    local group = part:match(":([%w_]+)")
    assert(group, "cursor part with no highlight: " .. part)
    h.eq(100, vim.api.nvim_get_hl(0, { name = group, link = false }).blend, "cursor highlight blend (" .. part .. ")")
  end

  vim.cmd.edit(file)
  vim.wait(100, function()
    return false
  end)
  h.eq(guicursor, vim.go.guicursor, "guicursor after leaving the Dashboard")
  h.eq(laststatus, vim.o.laststatus, "laststatus after leaving the Dashboard")
end)

h.test("deleting the Dashboard's buffer brings the cursor and statusline back", function()
  vim.env.PATH = path_without_colorscript(fake_colorscript("true"))
  close_dashboards()
  vim.cmd("silent! %bwipeout!") -- so :bd leaves an empty buffer
  local guicursor, laststatus = vim.go.guicursor, vim.o.laststatus
  open_dashboard(plain)
  h.eq(0, vim.o.laststatus, "laststatus on the Dashboard")

  vim.cmd.bdelete()
  vim.wait(100, function()
    return false
  end)
  h.eq("", vim.api.nvim_buf_get_name(0), "an empty buffer after :bd")
  h.eq(guicursor, vim.go.guicursor, "guicursor after :bd")
  h.eq(laststatus, vim.o.laststatus, "laststatus after :bd")
end)
