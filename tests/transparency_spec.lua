local h = require("harness")

-- Load everything that defines highlights or floats up front, so a group can't
-- pass "no background" just because its plugin hasn't defined it yet.
require("lazy").load({
  plugins = { "blink.cmp", "bufferline.nvim", "lualine.nvim", "mason.nvim", "noice.nvim", "which-key.nvim" },
})

-- Per theme, its own editor background (from its palette).
local themes = {
  ["catppuccin-frappe"] = "#303446",
  ["catppuccin-macchiato"] = "#24273a",
  ["catppuccin-mocha"] = "#1e1e2e",
  ["tokyonight-moon"] = "#222436",
  ["tokyonight-night"] = "#1a1b26",
  ["tokyonight-storm"] = "#24283b",
}

--- The background of `group`, following links.
local function bg(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false }).bg
end

local transparent = {
  -- editor
  "Normal",
  "NormalNC",
  "SignColumn",
  "LineNr",
  "FoldColumn",
  "EndOfBuffer",
  "WinSeparator",
  -- statusline and bufferline
  "StatusLine",
  "StatusLineNC",
  "TabLineFill",
  "BufferLineFill",
  "BufferLineBackground",
  "BufferLineBufferSelected",
  -- floats: generic, completion, which-key, Lazy, Mason, notifications, pickers and the explorer
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "Pmenu",
  "BlinkCmpMenu",
  "BlinkCmpMenuBorder",
  "BlinkCmpDoc",
  "BlinkCmpSignatureHelp",
  "WhichKeyNormal",
  "LazyNormal",
  "MasonNormal",
  "SnacksNotifierInfo",
  "SnacksPicker",
  "SnacksPickerList",
  "SnacksPickerInput",
  "SnacksPickerPreview",
  -- sidebars
  "NormalSB",
}

-- The "where am I" highlights keep a background.
local solid = { "CursorLine", "Visual", "PmenuSel", "BlinkCmpMenuSelection" }

-- Accent chips each theme gives a background to, which aren't panels and keep it.
local chips = {
  tokyonight = { "NoiceFormatProgressDone", "SnacksPickerPickWin", "TroubleCount" },
  catppuccin = { "MasonMutedBlockBold" },
}

for theme, background in pairs(themes) do
  h.test(theme .. ": editor, sidebars, bars and floats have no background", function()
    h.apply_theme(theme)
    local solid_groups = {}
    for _, group in ipairs(transparent) do
      if bg(group) then
        table.insert(solid_groups, ("%s (#%06x)"):format(group, bg(group)))
      end
    end
    h.eq({}, solid_groups, "groups with a background")
  end)

  h.test(theme .. ": the cursor line, selection and completion selection keep a background", function()
    h.apply_theme(theme)
    for _, group in ipairs(solid) do
      h.eq(true, bg(group) ~= nil, group .. " has a background")
    end
  end)

  h.test(theme .. ": accent chips (progress bar, badges, tab blocks) keep their background", function()
    h.apply_theme(theme)
    for _, group in ipairs(chips[theme:match("^%a+")]) do
      h.eq(true, bg(group) ~= nil, group .. " has a background")
    end
  end)

  h.test(theme .. ": the file explorer has no background", function()
    h.apply_theme(theme)
    local explorer = Snacks.explorer()
    vim.wait(2000, function()
      return explorer:is_active() == false
    end, 50)
    -- Each explorer window's Normal, as its 'winhighlight' maps it.
    local solid_windows, seen = {}, 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype:match("^snacks_") then
        seen = seen + 1
        local group = vim.wo[win].winhighlight:match("%f[%w]Normal:([%w_]+)") or "Normal"
        if bg(group) then
          table.insert(solid_windows, vim.bo[vim.api.nvim_win_get_buf(win)].filetype .. " " .. group)
        end
      end
    end
    explorer:close()
    h.eq(true, seen > 0, "explorer windows found")
    h.eq({}, solid_windows, "explorer windows with a background")
  end)

  h.test(theme .. ": the statusline shows the mode as coloured text on no background", function()
    h.apply_theme(theme)
    for _, section in ipairs({ "a", "b", "c" }) do
      for _, mode in ipairs({ "normal", "insert", "visual" }) do
        local group = ("lualine_%s_%s"):format(section, mode)
        h.eq(nil, bg(group), group .. " background")
      end
    end
    local normal = vim.api.nvim_get_hl(0, { name = "lualine_a_normal", link = false }).fg
    local insert = vim.api.nvim_get_hl(0, { name = "lualine_a_insert", link = false }).fg
    h.eq(true, normal ~= nil and insert ~= nil and normal ~= insert, "mode text coloured by mode")
  end)

  h.test(theme .. ": its own editor background is recorded before clearing", function()
    h.apply_theme(theme)
    h.eq(background, require("theme").background)
  end)
end

--- The top-left corner of `win`'s border: its window border, else a border
--- drawn as text (noice draws some borders as a window of their own).
local function corner(win)
  local border = vim.api.nvim_win_get_config(win).border
  local first = type(border) == "table" and border[1]
  first = type(first) == "table" and first[1] or first
  if first and first ~= "" then
    return first
  end
  local line = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, 1, false)[1] or ""
  return vim.fn.strcharpart(line, 0, 1)
end

--- Floating windows opened by `fn`, once they've appeared (or after 5s).
local function floats_opened_by(fn)
  local before = vim.api.nvim_list_wins()
  local function new()
    return vim.tbl_filter(function(win)
      return not vim.list_contains(before, win) and vim.api.nvim_win_get_config(win).relative ~= ""
    end, vim.api.nvim_list_wins())
  end
  fn()
  vim.wait(5000, function()
    return #new() > 0
  end, 50)
  -- Some UIs (pickers) open several windows; let the rest appear.
  vim.wait(300, function()
    return false
  end)
  return new()
end

--- Assert that some float opened by `fn` has a rounded border, then close them.
local function assert_rounded(what, fn)
  local wins = floats_opened_by(fn)
  local corners = vim.tbl_map(corner, wins)
  for _, win in ipairs(wins) do
    pcall(vim.api.nvim_win_close, win, true)
  end
  h.eq(true, vim.list_contains(corners, "╭"), what .. " float corners: " .. vim.inspect(corners))
end

h.test("a float opened without a border (hover, completion, which-key, Mason) gets a rounded one", function()
  assert_rounded("plain", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, false, { relative = "editor", row = 1, col = 1, width = 10, height = 2 })
  end)
end)

-- Lazy doesn't open its window when headless, so this checks its setting.
h.test("the Lazy window is set to a rounded border", function()
  h.eq("rounded", require("lazy.core.config").options.ui.border)
end)

h.test("pickers have a rounded border", function()
  local picker
  assert_rounded("picker", function()
    picker = Snacks.picker.files()
  end)
  picker:close()
end)

h.test("notifications have a rounded border", function()
  assert_rounded("notification", function()
    vim.notify("hello", vim.log.levels.INFO)
  end)
end)

h.test("LSP hover has a rounded border", function()
  local file = vim.fn.tempname() .. ".lua"
  vim.fn.writefile({ "print('x')" }, file)
  vim.cmd.edit(file)
  vim.wait(20000, function()
    return #vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" }) > 0
  end, 100)
  vim.api.nvim_win_set_cursor(0, { 1, 1 })
  -- Wait until lua_ls has hover content for `print` before asking for the float.
  vim.wait(20000, function()
    local params = vim.lsp.util.make_position_params(0, "utf-16")
    local res = vim.lsp.buf_request_sync(0, "textDocument/hover", params, 2000) or {}
    return vim.iter(vim.tbl_values(res)):any(function(r)
      return r.result ~= nil
    end)
  end, 500)
  assert_rounded("hover", function()
    vim.lsp.buf.hover()
  end)
end)

h.test("the statusline shows the pending plugin update count", function()
  local checker = require("lazy.manage.checker")
  local updated = checker.updated
  checker.updated = { "a", "b", "c" }
  require("lualine").refresh({ force = true })
  local line = vim.api.nvim_eval_statusline(vim.o.statusline, {}).str
  checker.updated = updated
  local icon = require("lazy.core.config").options.ui.icons.plugin
  h.eq(true, line:find(icon .. "3", 1, true) ~= nil, "statusline: " .. line)
end)

h.test("the update checker runs without notifying", function()
  local checker = require("lazy.core.config").options.checker
  h.eq({ true, false }, { checker.enabled, checker.notify })
end)
