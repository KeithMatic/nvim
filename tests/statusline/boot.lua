-- Not a spec of its own: statusline_spec.lua boots a second Neovim with this
-- file as its TEST_SPEC, to check the filename toggle survives a restart.
local h = require("harness")

h.test("boots showing the filename in the statusline", function()
  h.attach_ui(160, 30)
  vim.cmd.edit(vim.env.EXPECT_FILE)
  local name = vim.fs.basename(vim.env.EXPECT_FILE)
  local text = ""
  vim.wait(5000, function()
    text = h.statusline()
    return text:find(name, 1, true) ~= nil
  end, 50)
  h.eq(true, text:find(name, 1, true) ~= nil, "statusline shows " .. name .. "\nstatusline: " .. text)
end)
