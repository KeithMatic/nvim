-- Not a spec of its own: statusline_spec.lua boots a second Neovim with this
-- file as its TEST_SPEC, to check the filename toggle survives a restart.
-- EXPECT_FILENAME is "shown" or "hidden".
local h = require("harness")

h.test("boots with the filename " .. vim.env.EXPECT_FILENAME .. " in the statusline", function()
  h.attach_ui(160, 30)
  vim.cmd.edit(vim.env.EXPECT_FILE)
  local name = vim.fs.basename(vim.env.EXPECT_FILE)
  local want = vim.env.EXPECT_FILENAME == "shown"
  local text = ""
  -- Wait for lualine to draw (the file size shows), then for the filename.
  vim.wait(5000, function()
    text = h.statusline()
    return text:find("%d+%.?%d*[bkmg]") ~= nil and (text:find(name, 1, true) ~= nil) == want
  end, 50)
  h.eq(want, text:find(name, 1, true) ~= nil, "statusline shows " .. name .. "\nstatusline: " .. text)
end)
