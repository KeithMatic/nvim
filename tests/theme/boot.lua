-- Not a spec of its own: theme_spec.lua and tint_spec.lua boot a second Neovim
-- with this file as its TEST_SPEC, to check what a fresh start restores from
-- the saved state.
local h = require("harness")

h.test("boots with " .. vim.env.EXPECT_THEME .. " and no errors", function()
  h.eq(vim.env.EXPECT_THEME, vim.g.colors_name, "theme after boot")
  h.eq({}, h.errors())
end)

-- Optionally, the backgrounds some groups should boot with: JSON, group name to "#rrggbb".
for group, expected in pairs(vim.json.decode(vim.env.EXPECT_BG or "{}")) do
  h.test(("boots with %s's background %s"):format(group, expected), function()
    local bg = vim.api.nvim_get_hl(0, { name = group, link = false }).bg
    h.eq(expected, bg and ("#%06x"):format(bg))
  end)
end
