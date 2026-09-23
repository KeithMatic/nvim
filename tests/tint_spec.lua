local h = require("harness")

-- The completion menu defines its highlights when it loads; load it first so
-- its definitions can't win just because they came later.
require("lazy").load({ plugins = { "blink.cmp" } })

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- The background of `group`, following links, as "#rrggbb".
local function bg(group)
  local value = vim.api.nvim_get_hl(0, { name = group, link = false }).bg
  return value and ("#%06x"):format(value)
end

--- The saved state file's contents, or nil.
local function saved()
  return vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file, "b") or nil
end

--- Run `fn` with the saved state set to `content` (nil: no state file), then
--- put back whatever was saved before, so other specs boot as they would have.
local function with_state(content, fn)
  local before = saved()
  if content then
    vim.fn.writefile(vim.split(content, "\n"), state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  local ok, err = pcall(fn)
  if before then
    vim.fn.writefile(before, state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  if not ok then
    error(err, 0)
  end
end

--- Boot a second headless Neovim on this config and assert that it starts with
--- `theme`, the given group backgrounds and no errors.
---@param backgrounds table<string, string> group name to "#rrggbb"
local function assert_boots_with(theme, backgrounds)
  local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
  local cmd = { "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }
  local env =
    { TEST_SPEC = root .. "/tests/theme/boot.lua", EXPECT_THEME = theme, EXPECT_BG = vim.json.encode(backgrounds) }
  local result = vim.system(cmd, { env = env, text = true }):wait(60000)
  h.eq(0, result.code, "second instance:\n" .. (result.stdout or "") .. (result.stderr or ""))
end

--- The group the Explorer draws its cursor line with while it has focus.
local function explorer_cursorline_group()
  local focused = h.focus_explorer()
  local group = vim.wo.winhighlight:match("%f[%w]CursorLine:([%w_]+)") or "CursorLine"
  vim.cmd("Neotree close")
  assert(focused, "the Explorer didn't get focus")
  return group
end

--- The group blink's completion menu draws its selected item with.
local function completion_selection_group()
  local winhl = require("blink.cmp.config").completion.menu.winhighlight
  return winhl:match("%f[%w]CursorLine:([%w_]+)")
end

-- #ff0000 at 0.3 over each theme's own background.
local red = {
  ["tokyonight-moon"] = "#641926",
  ["tokyonight-night"] = "#5f131b",
  ["catppuccin-frappe"] = "#6e2431",
}

h.test(":Tint #ff0000 0.3 tints the cursor line, the Explorer line and the completion selection", function()
  with_state(nil, function()
    h.apply_theme("tokyonight-moon")
    vim.cmd("Tint #ff0000 0.3")
    h.eq(red["tokyonight-moon"], bg("CursorLine"), "CursorLine")
    h.eq(red["tokyonight-moon"], bg(explorer_cursorline_group()), "Explorer cursor line")
    h.eq(red["tokyonight-moon"], bg(completion_selection_group()), "completion selection")
  end)
end)

h.test("the tint is restored on the next start", function()
  with_state(nil, function()
    h.apply_theme("tokyonight-moon")
    vim.cmd("Tint #ff0000 0.3")
    assert_boots_with("tokyonight-moon", { CursorLine = red["tokyonight-moon"] })
  end)
end)

h.test("the tint survives theme switches, blended against the new theme's background", function()
  with_state(nil, function()
    h.apply_theme("tokyonight-moon")
    vim.cmd("Tint #ff0000 0.3")
    for _, theme in ipairs({ "tokyonight-night", "catppuccin-frappe" }) do
      h.apply_theme(theme)
      h.eq(red[theme], bg("CursorLine"), theme .. " CursorLine")
      h.eq(red[theme], bg("NeoTreeCursorLine"), theme .. " Explorer cursor line")
      h.eq(red[theme], bg("BlinkCmpMenuSelection"), theme .. " completion selection")
    end
    assert_boots_with("catppuccin-frappe", { CursorLine = red["catppuccin-frappe"] })
  end)
end)

h.test("invalid :Tint input errors and changes nothing", function()
  with_state(nil, function()
    h.apply_theme("tokyonight-moon")
    vim.cmd("Tint #ff0000 0.3")
    local state = saved()
    local groups = { "CursorLine", "NeoTreeCursorLine", "BlinkCmpMenuSelection" }
    local before = vim.tbl_map(bg, groups)
    for _, args in ipairs({
      "#zzzzzz 0.3",
      "#ff00 0.3",
      "red 0.3",
      "#00ff00 1.5",
      "#00ff00 -0.1",
      "#00ff00 abc",
      "#00ff00",
    }) do
      local errors = #h.errors()
      pcall(vim.cmd, "Tint " .. args)
      local reported = vim.wait(1000, function()
        return #h.errors() > errors
      end, 20)
      h.eq(true, reported, ":Tint " .. args .. " reports an error")
      h.eq(before, vim.tbl_map(bg, groups), ":Tint " .. args .. " leaves the highlights")
      h.eq(state, saved(), ":Tint " .. args .. " leaves the saved state")
    end
  end)
end)

h.test("with no saved tint, startup uses a default one", function()
  with_state('{"theme":"tokyonight-moon"}', function()
    -- #ffffff at 0.1 over tokyonight-moon's background.
    assert_boots_with("tokyonight-moon", { CursorLine = "#383a4a" })
  end)
end)

h.test("a corrupt saved tint falls back to the default", function()
  with_state('{"theme":"tokyonight-moon","tint":{"color":"nope","fade":7}}', function()
    assert_boots_with("tokyonight-moon", { CursorLine = "#383a4a" })
  end)
end)

-- Per theme, each mode's colour from its palette, and that colour at 0.2 over
-- the theme's background: the cursor line in that mode (the visual selection,
-- for visual mode).
local modes = {
  ["tokyonight-moon"] = {
    Insert = { "#c3e88d", "#424b47" },
    Delete = { "#ff757f", "#4e3445" },
    Copy = { "#ffc777", "#4e4543" },
    Visual = { "#c099ff", "#423b5e" },
  },
  ["catppuccin-mocha"] = {
    Insert = { "#a6e3a1", "#394545" },
    Delete = { "#f38ba8", "#493446" },
    Copy = { "#f9e2af", "#4a4548" },
    Visual = { "#cba6f7", "#413956" },
  },
}

for theme, colours in pairs(modes) do
  h.test(theme .. ": mode colours come from its palette, faded over its background", function()
    h.apply_theme(theme)
    for mode, colour in pairs(colours) do
      local line = mode == "Visual" and "ModesVisualVisual" or ("Modes%sCursorLine"):format(mode)
      h.eq(colour[1], bg("Modes" .. mode), "Modes" .. mode)
      h.eq(colour[2], bg(line), line)
    end
  end)
end

h.test("mode colours come from the palette from the start", function()
  with_state('{"theme":"catppuccin-mocha"}', function()
    local colours = modes["catppuccin-mocha"]
    assert_boots_with("catppuccin-mocha", {
      ModesInsertCursorLine = colours.Insert[2],
      ModesVisualVisual = colours.Visual[2],
    })
  end)
end)

h.test("insert mode tints the cursor line with the insert colour", function()
  h.apply_theme("tokyonight-moon")
  vim.cmd.enew()
  -- Look at the window from inside insert mode, then leave it.
  local mode, group
  _G.tint_spec_capture = function()
    mode = vim.fn.mode()
    group = vim.wo.winhighlight:match("%f[%w]CursorLine:([%w_]+)")
  end
  vim.api.nvim_feedkeys(vim.keycode("i<Cmd>lua tint_spec_capture()<CR><Esc>"), "nx", false)
  _G.tint_spec_capture = nil
  h.eq("i", mode, "in insert mode")
  h.eq(bg("ModesInsertCursorLine"), group and bg(group), "insert-mode cursor line")
end)
