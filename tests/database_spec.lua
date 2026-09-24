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

h.test("blink offers dadbod completion in a .sql buffer", function()
  local path = vim.fn.tempname() .. ".sql"
  vim.fn.writefile({}, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  h.eq("sql", vim.bo.filetype, "filetype")
  local providers = require("blink.cmp.sources.lib").get_enabled_providers("default")
  h.eq(true, providers.dadbod ~= nil, ("dadbod among %s"):format(vim.inspect(vim.tbl_keys(providers))))
end)
