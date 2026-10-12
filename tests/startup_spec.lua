local h = require("harness")

-- A fresh start, per Curated theme (built in, added, and the Mix): a second
-- Neovim boots with the theme saved and runs tests/startup/boot.lua. Plugins
-- that load after the startup theme (lualine, noice, the notifier, ...) must
-- look as they do when the theme is applied with everything loaded.
local curated_themes = require("curated_themes")
curated_themes.read_added()

for _, name in ipairs(curated_themes.list()) do
  h.test(name .. ": a fresh start looks as applying it does", function()
    h.with_state(vim.json.encode({ theme = name }), function()
      h.boot("startup/boot.lua", { EXPECT_THEME = name }, 120000)
    end)
  end)
end
