local h = require("harness")
local terminal = require("terminal")

-- The first <leader>ft or <leader>fT, before the Terminal manager was ever
-- shown, starts it with just that terminal: not the project one as well.

h.attach_ui(160, 40)

local project = vim.fn.tempname()
vim.fn.mkdir(project .. "/src", "p")
project = assert(vim.uv.fs_realpath(project))
vim.fn.writefile({}, project .. "/src/main.py")
vim.fn.mkdir(project .. "/.git")
vim.fn.chdir(project)
vim.cmd.edit(project .. "/src/main.py")

h.test("the first <leader>fT starts the Terminal manager with only its terminal", function()
  h.eq(nil, package.loaded["floaterm"], "floaterm loaded before")
  h.feed("<leader>fT", "mx")
  h.eq(true, vim.wait(5000, terminal.shown, 20), "the Terminal manager shown")
  local state = require("floaterm.state")
  local terminals = vim.tbl_map(function(term)
    return { name = term.name, cmd = term.cmd }
  end, state.terminals)
  h.eq({ { name = "src", cmd = "cd " .. vim.fn.shellescape(project .. "/src") } }, terminals, "terminals")
  h.eq(state.terminals[1].buf, vim.api.nvim_win_get_buf(state.win), "its terminal shown")
end)

h.test("nothing errored", function()
  h.eq({}, h.errors(), "errors")
end)
