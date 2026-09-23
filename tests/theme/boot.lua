-- Not a spec of its own: theme_spec.lua boots a second Neovim with this file
-- as its TEST_SPEC, to check what a fresh start restores from the saved state.
local h = require("harness")

h.test("boots with " .. vim.env.EXPECT_THEME .. " and no errors", function()
  h.eq(vim.env.EXPECT_THEME, vim.g.colors_name, "theme after boot")
  h.eq({}, h.errors())
end)
