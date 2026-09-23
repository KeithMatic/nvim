local h = require("harness")

h.test(":Sqmeow exists", function()
  h.eq(2, vim.fn.exists(":Sqmeow"), ":Sqmeow command")
end)

h.test("dadbod-ui's commands don't exist", function()
  for _, cmd in ipairs({ "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" }) do
    h.eq(0, vim.fn.exists(":" .. cmd), ":" .. cmd .. " command")
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
