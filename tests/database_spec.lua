local h = require("harness")

h.test(":Sqmeow exists", function()
  h.eq(2, vim.fn.exists(":Sqmeow"), ":Sqmeow command")
end)

h.test("dadbod-ui is disabled", function()
  local spec = require("lazy.core.config").spec
  h.eq(true, spec.disabled["vim-dadbod-ui"] ~= nil, "vim-dadbod-ui among lazy's disabled plugins")
  h.eq(nil, spec.plugins["vim-dadbod-ui"], "vim-dadbod-ui among lazy's plugins")
end)

h.test("<leader>D keys drive the Database client", function()
  local leader = vim.g.mapleader
  for key, desc in pairs({ d = "Toggle Database", c = "Cancel Query", a = "Add Connection", s = "New Scratchpad" }) do
    h.eq(desc, vim.fn.maparg(leader .. "D" .. key, "n", false, true).desc, "<leader>D" .. key)
  end
end)

--- Open a fresh, empty file with extension `ext`.
local function open(ext)
  local path = vim.fn.tempname() .. "." .. ext
  vim.fn.writefile({}, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

h.test("<leader>Dr and <leader>De run queries in a .sql buffer", function()
  local leader = vim.g.mapleader
  open("sql")
  for _, map in ipairs({
    { lhs = "Dr", mode = "n", desc = "Run Statement" },
    { lhs = "Dr", mode = "x", desc = "Run Selection" },
    { lhs = "De", mode = "n", desc = "Run File" },
  }) do
    local mapping = vim.fn.maparg(leader .. map.lhs, map.mode, false, true)
    local what = ("%s-mode <leader>%s"):format(map.mode, map.lhs)
    h.eq(map.desc, mapping.desc, what)
    h.eq(1, mapping.buffer, what .. " is buffer-local")
  end
end)

h.test("<leader>Dr and <leader>De aren't set outside SQL", function()
  local leader = vim.g.mapleader
  open("lua")
  for _, lhs in ipairs({ "Dr", "De" }) do
    h.eq("", vim.fn.maparg(leader .. lhs, "n"), "<leader>" .. lhs .. " in a Lua buffer")
  end
end)

h.test("a .sql buffer gets sqmeow's scratchpad keys", function()
  local leader = vim.g.mapleader
  open("sql")
  for _, map in ipairs({
    { lhs = "<CR>", mode = "n", desc = "sqmeow: Run the statement under the cursor" },
    { lhs = "<CR>", mode = "x", desc = "sqmeow: Run the selection" },
    { lhs = leader .. "E", mode = "n", desc = "sqmeow: Run the whole buffer" },
    { lhs = "<C-c>", mode = "n", desc = "sqmeow: Stop the running query" },
    { lhs = "?", mode = "n", desc = "sqmeow: Show these mappings" },
  }) do
    local mapping = vim.fn.maparg(map.lhs, map.mode, false, true)
    local what = ("%s-mode %s"):format(map.mode, map.lhs)
    h.eq(map.desc, mapping.desc, what)
    h.eq(1, mapping.buffer, what .. " is buffer-local")
  end
end)

h.test("sqmeow's scratchpad keys stay out of other buffers", function()
  open("lua")
  h.eq("", vim.fn.maparg("<CR>", "n"), "<CR> in a Lua buffer")
end)

--- Make `connection` sqmeow's only, current one, as if opened in the drawer.
local function use_connection(connection)
  local state = require("sqmeow.state")
  state.connections = { [connection.id] = connection }
  state.current = connection.id
end

--- Open a .sql buffer and enter insert mode's autocmds, where completion reads b:db.
local function insert_in_sql()
  open("sql")
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = 0 })
end

h.test("dadbod completion follows the database sqmeow runs queries on", function()
  use_connection({
    id = 91,
    name = "PostgreSQL@18/dvdrental",
    url = "postgres://postgres:secret@localhost/",
    database = "dvdrental",
    state = "connected",
  })
  insert_in_sql()
  h.eq("postgres://postgres:secret@localhost/dvdrental", vim.b.db, "b:db for a cluster's database")

  use_connection({ id = 92, name = "store", url = "postgres://postgres@localhost:5433/store", state = "connected" })
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = 0 })
  h.eq("postgres://postgres@localhost:5433/store", vim.b.db, "b:db after switching connection")

  use_connection({ id = 93, name = "gone", url = "postgres://localhost/gone", state = "closed" })
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = 0 })
  h.eq(nil, vim.b.db, "b:db once nothing is connected")
end)

h.test("a b:db set by hand is left alone", function()
  use_connection({ id = 94, name = "store", url = "postgres://localhost/store", state = "connected" })
  open("sql")
  vim.b.db = "postgres://localhost/mine"
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = 0 })
  h.eq("postgres://localhost/mine", vim.b.db)
end)

h.test("database completions rank above snippets", function()
  local providers = LazyVim.opts("blink.cmp").sources.providers
  local snippets = (providers.snippets or {}).score_offset or 0
  h.eq(true, (providers.dadbod.score_offset or 0) > snippets, "dadbod's score_offset above snippets'")
end)

h.test("blink offers dadbod completion in a .sql buffer", function()
  local path = vim.fn.tempname() .. ".sql"
  vim.fn.writefile({}, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  h.eq("sql", vim.bo.filetype, "filetype")
  local providers = require("blink.cmp.sources.lib").get_enabled_providers("default")
  h.eq(true, providers.dadbod ~= nil, ("dadbod among %s"):format(vim.inspect(vim.tbl_keys(providers))))
end)
