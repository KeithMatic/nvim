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

--- `group`'s background, links followed, as "#rrggbb"; nil when it has none.
---@param group string
---@return string?
local function background(group)
  local bg = vim.api.nvim_get_hl(0, { name = group, link = false }).bg
  return bg and ("#%06x"):format(bg)
end

-- The accents a float keeps a background for, by name: the selected item (the
-- Tint), the cursor, search matches, the scrollbar thumb, the picker's window
-- labels, and noice's confirm buttons and progress bar.
local accents = { "Sel", "Cursor", "Visual", "Search", "Thumb", "PickWin", "NoiceFormatConfirm", "NoiceFormatProgress" }

---@param group string
---@return boolean
local function accent(group)
  for _, part in ipairs(accents) do
    if group:find(part, 1, true) then
      return true
    end
  end
  return false
end

--- The Float sweep's check: every group the open floats draw with that has a
--- background and isn't an accent, as "filetype: group (#rrggbb)". A float
--- draws with what its 'winhighlight' maps the float groups to, its title's and
--- footer's groups, and what its text and virtual text are highlighted with.
---@return string[]
local function solid_in_floats()
  local found = {}
  local function check(win, group)
    if type(group) == "string" and group ~= "" and not accent(group) and background(group) then
      local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      found[("%s: %s (%s)"):format(filetype, group, background(group))] = true
    end
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      local map = {}
      for from, to in vim.wo[win].winhighlight:gmatch("([^:,]+):([^,]*)") do
        map[from] = to
      end
      for _, group in ipairs({ "NormalFloat", "FloatBorder", "FloatTitle", "FloatFooter" }) do
        check(win, map[group] or group)
      end
      check(win, map.Normal or map.NormalFloat or "NormalFloat")
      for _, chunk in ipairs(vim.list_extend(vim.deepcopy(config.title or {}), config.footer or {})) do
        check(win, chunk[2])
      end
      local buf = vim.api.nvim_win_get_buf(win)
      for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
        local details = mark[4]
        check(win, details.hl_group)
        for _, chunk in ipairs(details.virt_text or {}) do
          for _, group in ipairs(type(chunk[2]) == "table" and chunk[2] or { chunk[2] }) do
            check(win, group)
          end
        end
      end
    end
  end
  local list = vim.tbl_keys(found)
  table.sort(list)
  return list
end

--- Whether noice shows the cmdline of type `type` (":", "/", "@" for input()),
--- with its icon when the format has one (drawn as virtual text).
---@param type string
---@param icon boolean
local function cmdline_shown(type, icon)
  local pos = require("noice").api.get_cmdline_position()
  if vim.fn.getcmdtype() ~= type or not (pos and vim.api.nvim_win_is_valid(pos.win)) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(pos.win)
  return not icon or #vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { type = "virt_text" }) > 0
end

-- The cmdline in each format noice shows, by the keys that open it; input()
-- through a command that asks for it, with no icon.
local cmdline_formats = {
  { name = "command", keys = ":", type = ":" },
  { name = "search", keys = "/", type = "/" },
  { name = "backward search", keys = "?", type = "?" },
  { name = "filter (shell)", keys = ":!", type = ":" },
  { name = "Lua", keys = ":lua ", type = ":" },
  { name = "help", keys = ":help ", type = ":" },
  { name = "input()", keys = ":lua vim.fn.input('Name: ')<CR>", type = "@", no_icon = true },
}

for _, format in ipairs(cmdline_formats) do
  h.test(theme .. ": the " .. format.name .. " cmdline draws nothing on a background", function()
    local solid
    h.drive(format.keys, {
      function()
        if not cmdline_shown(format.type, not format.no_icon) then
          return false
        end
        solid = solid_in_floats()
      end,
    })
    h.eq(0, #solid, "groups with a background:\n" .. table.concat(solid, "\n"))
  end)
end

--- Whether `group` is set by a plugin's own doing, which a theme change doesn't
--- redo: the cursors, which modes.nvim colours in each mode (themes link
--- CursorIM, lCursor, noice's and hop's to Cursor), which-key's icons, linked to
--- mini.icons' colours only as which-key loads, and lualine's groups for modes
--- other than normal, brought up to date only when that mode shows.
---@param group string
---@return boolean
local function plugin_set(group)
  return group == "CursorIM"
    or group:match("Cursor$") ~= nil
    or group:match("^WhichKeyIcon") ~= nil
    or (group:match("^lualine_") ~= nil and not group:match("_normal$"))
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
