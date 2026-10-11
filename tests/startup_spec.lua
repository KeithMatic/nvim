local h = require("harness")

-- A fresh start, per Curated theme (built in, added, and the Mix): a second
-- Neovim boots with the theme saved and runs tests/startup/boot.lua. Plugins
-- that load after the startup theme (lualine, noice, the notifier, ...) must
-- look as they do when the theme is applied with everything loaded.
local theme = require("theme")
theme.detect()

local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))

for _, name in ipairs(theme.curated()) do
  h.test(name .. ": a fresh start looks as applying it does", function()
    h.with_state(vim.json.encode({ theme = name }), function()
      local cmd = { "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }
      local env = { TEST_SPEC = root .. "/tests/startup/boot.lua", EXPECT_THEME = name }
      local result = vim.system(cmd, { env = env, text = true }):wait(120000)
      h.eq(0, result.code, "fresh start:\n" .. (result.stdout or ""))
    end)
  end)
end
