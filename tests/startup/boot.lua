-- Not a spec of its own: startup_spec.lua boots a second Neovim with this file
-- as its TEST_SPEC, once per Curated theme saved as the theme, to check that a
-- fresh start looks as applying that theme does.
local h = require("harness")

h.attach_ui(120, 40)

local theme = vim.env.EXPECT_THEME

h.test(theme .. ": starts as itself", function()
  -- Or as the variant it is: oasis is oasis-moonlight.
  local name = vim.g.colors_name
  h.eq(true, name == theme or vim.startswith(name, theme .. "-"), "started as " .. tostring(name))
end)

--- Every defined highlight group, links followed: what each one draws with.
--- Not `default`, which changes nothing drawn.
---@return table<string, table>
local function look()
  local groups = {}
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    hl.default = nil
    if next(hl) then
      groups[name] = hl
    end
  end
  return groups
end

h.test(theme .. ": the statusline has no background after a fresh start", function()
  -- What it draws with, as evaluated: not the screen's cells, which lualine
  -- renumbers by defining highlights as it draws.
  local drawn = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true })
  local solid = {}
  for _, part in ipairs(drawn.highlights) do
    for _, group in ipairs(part.groups or { part.group }) do
      local bg = vim.api.nvim_get_hl(0, { name = group, link = false }).bg
      if bg and not vim.list_contains(solid, group) then
        table.insert(solid, ("%s (#%06x)"):format(group, bg))
      end
    end
  end
  h.eq(0, #solid, "statusline groups with a background:\n" .. table.concat(solid, "\n"))
end)

--- Whether `group` is set by a plugin's own doing, which a theme change doesn't
--- redo: the cursors, which modes.nvim colours in each mode (themes link
--- CursorIM, lCursor, noice's and hop's to Cursor), and which-key's icons,
--- linked to mini.icons' colours only as which-key loads.
---@param group string
---@return boolean
local function plugin_set(group)
  return group == "CursorIM" or group:match("Cursor$") ~= nil or group:match("^WhichKeyIcon") ~= nil
end

h.test(theme .. ": with every plugin loaded, it looks as when the theme is applied again", function()
  local unloaded = {}
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    if not plugin._.loaded then
      table.insert(unloaded, name)
    end
  end
  require("lazy").load({ plugins = unloaded })
  vim.wait(200, function()
    return false
  end)
  local startup = look()
  h.apply_theme(theme)
  local again = look()

  -- Groups only one side defines are the plugin's doing, not the look's: some
  -- define theirs on first use (blink), some don't define them again after a
  -- theme change (aerial, lspsaga, crates).
  local differ = {}
  for name in pairs(again) do
    if startup[name] and not plugin_set(name) and not vim.deep_equal(startup[name], again[name]) then
      table.insert(
        differ,
        ("%s: %s, applied again %s"):format(
          name,
          vim.inspect(startup[name], { newline = " ", indent = "" }),
          vim.inspect(again[name], { newline = " ", indent = "" })
        )
      )
    end
  end
  table.sort(differ)
  h.eq(0, #differ, "groups that differ from applying the theme again:\n" .. table.concat(differ, "\n"))
end)
