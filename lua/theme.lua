-- Themes: the curated list of dark themes, persistence, transparency and the
-- tint. Every theme change, however it happens (the picker, `:colorscheme`),
-- goes through one ColorScheme hook, which:
--   1. records the theme's own editor background (`M.background`),
--   2. gives modes.nvim the theme's mode colours, and the background to fade
--      them over,
--   3. tints the "where am I" lines: the tint colour faded over that background,
--   4. makes the reference highlights (other occurrences of the word under
--      the cursor) underlines with no background,
--   5. saves the theme so the next start restores it (live previews in the
--      picker and the theme applied at startup aren't saved),
--   6. clears the background of whatever the themes' native transparency
--      options leave solid, so the terminal's glass shows through.
local M = {}

-- The only themes the picker offers.
M.themes = {
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha",
  "tokyonight-night",
  "tokyonight-storm",
  "tokyonight-moon",
}

-- Used when nothing is saved, or the saved theme won't load.
M.default = "tokyonight-moon"

-- The tint colour, and how much of it shows over the theme's background (0 to
-- 1). Used when nothing valid is saved; `:Tint` changes it.
M.default_tint = { color = "#ffffff", fade = 0.1 }

-- What the tint colours: the cursor line (and its gutter), the explorer's line
-- and the selected completion item.
local tinted = { "CursorLine", "CursorLineNr", "CursorLineSign", "SnacksPickerListCursorLine", "BlinkCmpMenuSelection" }

-- The reference highlights: other occurrences of the word under the cursor.
local references = { "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- The saved state, or an empty table when it's missing or unreadable.
---@return {theme?: string, tint?: {color: string, fade: number}}
local function read_state()
  local ok, state = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state_file), "\n"))
  end)
  return ok and type(state) == "table" and state or {}
end

--- Merge `changes` into the saved state.
---@param changes table
local function save_state(changes)
  local state = vim.tbl_extend("force", read_state(), changes)
  vim.fn.mkdir(vim.fs.dirname(state_file), "p")
  vim.fn.writefile({ vim.json.encode(state) }, state_file)
end

-- True while startup applies the saved theme (or a fallback), which is never saved.
local restoring = false

--- Whether a colorscheme picker is open, so theme changes are only previews.
local function previewing()
  return #Snacks.picker.get({ source = "colorschemes", tab = false }) > 0
end

-- What transparency clears: panel and float backgrounds, named or by prefix.
-- Accent "chips" (progress bars, badges, Mason's tab blocks, window-pick labels)
-- aren't panels, so they're left out, as is anything whose name marks a "where
-- am I" highlight or a scrollbar.
local transparency = {
  groups = {
    "Normal",
    "NormalNC",
    "NormalSB",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "FloatFooter",
    "SignColumn",
    "SignColumnSB",
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
    "FoldColumn",
    "EndOfBuffer",
    "WinSeparator",
    "VertSplit",
    "StatusLine",
    "StatusLineNC",
    "TabLine",
    "TabLineFill",
    "WinBar",
    "WinBarNC",
    "MsgArea",
    "Pmenu",
    "LazyNormal",
    "MasonNormal",
    "SnacksNormal",
    "SnacksNormalNC",
    "SnacksWinBar",
    "SnacksBackdrop",
    "TroubleNormal",
    "TroubleNormalNC",
  },
  prefixes = {
    "BlinkCmp",
    "BufferLine",
    "NoiceCmdline",
    "NoiceConfirm",
    "NoiceMini",
    "NoicePopup",
    "NoiceSplit",
    "Saga",
    "SnacksDashboard",
    "SnacksInput",
    "SnacksNotifier",
    "SnacksPicker",
    "WhichKey",
  },
  keep = { "Cursor", "Sel", "Visual", "Search", "Diff", "Thumb", "ScrollBar", "Scrollbar", "PickWin" },
}

local function should_clear(name)
  local listed = vim.list_contains(transparency.groups, name)
    or vim.iter(transparency.prefixes):any(function(prefix)
      return vim.startswith(name, prefix)
    end)
  return listed and not vim.iter(transparency.keep):any(function(word)
    return name:find(word, 1, true) ~= nil
  end)
end

--- Clear the background of every group transparency covers. Linked groups are
--- left alone: they follow their target.
local function make_transparent()
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if not hl.link and (hl.bg or hl.ctermbg) and should_clear(name) then
      -- A `default` definition never replaces an existing one, so drop the flag.
      hl.bg, hl.ctermbg, hl.default = nil, nil, nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

--- The current theme's own editor background and mode colours, as "#rrggbb".
--- The curated themes' native transparency has already cleared Normal, so
--- theirs come from their palette. Other themes get only a background, and
--- modes.nvim's own colours.
---@return {bg?: string, insert?: string, visual?: string, delete?: string, copy?: string}
local function theme_palette()
  local name = vim.g.colors_name or ""
  local style = name:match("^tokyonight%-(%a+)$")
  if style then
    local c = require("tokyonight.colors").setup({ style = style })
    return { bg = c.bg, insert = c.green, visual = c.magenta, delete = c.red, copy = c.yellow }
  end
  local flavour = name:match("^catppuccin%-?(%a*)$")
  if flavour then
    local c = require("catppuccin.palettes").get_palette(flavour ~= "" and flavour or nil)
    return { bg = c.base, insert = c.green, visual = c.mauve, delete = c.red, copy = c.yellow }
  end
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  return { bg = bg and ("#%06x"):format(bg) }
end

--- Whether `color` is a "#rrggbb" colour.
local function valid_color(color)
  return type(color) == "string" and color:match("^#%x%x%x%x%x%x$") ~= nil
end

--- Whether `fade` is a number from 0 to 1.
local function valid_fade(fade)
  return type(fade) == "number" and fade >= 0 and fade <= 1
end

--- `color` at `alpha` over `base`, all "#rrggbb": a solid colour that looks
--- like `color` faded.
local function blend(color, base, alpha)
  local channels = {}
  for i = 2, 6, 2 do
    local c, b = tonumber(color:sub(i, i + 1), 16), tonumber(base:sub(i, i + 1), 16)
    table.insert(channels, math.floor(alpha * c + (1 - alpha) * b + 0.5))
  end
  return ("#%02x%02x%02x"):format(unpack(channels))
end

--- Give every tinted group the tint faded over the theme's background.
local function apply_tint()
  local bg = blend(M.tint.color, M.background or "#000000", M.tint.fade)
  for _, name in ipairs(tinted) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    hl.bg = bg
    vim.api.nvim_set_hl(0, name, hl)
  end
end

--- Make every reference group an underline with no background.
local function underline_references()
  for _, name in ipairs(references) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    hl.bg, hl.ctermbg, hl.reverse, hl.underline = nil, nil, nil, true
    vim.api.nvim_set_hl(0, name, hl)
  end
end

--- The hook that runs on every theme change.
local function on_change()
  local palette = theme_palette()
  M.background = palette.bg
  -- modes.nvim's own ColorScheme hook, which runs after this one, reads its
  -- colours from these groups.
  local mode_groups = { insert = "ModesInsert", visual = "ModesVisual", delete = "ModesDelete", copy = "ModesCopy" }
  for mode, group in pairs(mode_groups) do
    if palette[mode] then
      vim.api.nvim_set_hl(0, group, { bg = palette[mode] })
    end
  end
  apply_tint()
  underline_references()
  if not (restoring or previewing()) then
    save_state({ theme = vim.g.colors_name })
  end
  -- Scheduled, to run after plugins (bufferline, lualine, …) redefine their
  -- highlights for the new theme.
  vim.schedule(make_transparent)
end

--- LazyVim's `colorscheme` option: set up the change hook, then apply the
--- saved theme, falling back to the default.
function M.load()
  local tint = read_state().tint
  M.tint = type(tint) == "table" and valid_color(tint.color) and valid_fade(tint.fade) and tint or M.default_tint
  vim.api.nvim_create_user_command("Tint", function(cmd)
    M.set_tint(unpack(cmd.fargs))
  end, { nargs = "*", desc = "Tint the cursor line: :Tint <#rrggbb> <fade 0-1>" })

  local group = vim.api.nvim_create_augroup("theme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = on_change })
  -- Plugins that load later define their highlights then; clear those too.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "LazyLoad", "VeryLazy" },
    callback = function()
      vim.schedule(make_transparent)
    end,
  })
  -- Scheduled, so it also covers LazyVim's own fallback (habamax) should the default fail too.
  restoring = true
  vim.schedule(function()
    restoring = false
  end)
  local saved = read_state().theme
  if not (type(saved) == "string" and pcall(vim.cmd.colorscheme, saved)) then
    vim.cmd.colorscheme(M.default)
  end
end

--- Set the tint to `color` faded to `fade` (from 0, none, to 1, solid), apply it
--- and save it. Invalid input is reported, and changes nothing.
---@param color? string "#rrggbb"
---@param fade? string|number
function M.set_tint(color, fade)
  local problem
  if not valid_color(color) then
    problem = "Not a #rrggbb colour: " .. (color or "(none)")
  elseif not valid_fade(tonumber(fade)) then
    problem = "Not a fade from 0 to 1: " .. (fade or "(none)")
  end
  if problem then
    local usage = "Usage: :Tint <#rrggbb> <fade 0-1>, e.g. :Tint #7aa2f7 0.3"
    return vim.notify(problem .. "\n" .. usage, vim.log.levels.ERROR, { title = "Tint" })
  end
  M.tint = { color = color:lower(), fade = tonumber(fade) }
  apply_tint()
  save_state({ tint = M.tint })
end

--- Run a plugin's `setup` so that it, and the ColorScheme hooks it creates, see
--- Normal with the theme's own background instead of none: for plugins that
--- fade colours over it (modes.nvim). Everything else still sees it cleared.
---@param setup fun()
function M.with_background(setup)
  local group = vim.api.nvim_create_augroup("theme", { clear = false })
  local normal
  local function solidify_normal()
    normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    if M.background then
      vim.api.nvim_set_hl(0, "Normal", vim.tbl_extend("force", normal, { bg = M.background }))
    end
  end
  local function restore_normal()
    vim.api.nvim_set_hl(0, "Normal", normal)
  end
  -- Hooks run in the order they were created, so the plugin's run in between.
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = solidify_normal })
  solidify_normal()
  setup()
  restore_normal()
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = restore_normal })
end

--- A colorscheme picker, with live preview, limited to the curated themes.
function M.pick()
  Snacks.picker.colorschemes({
    transform = function(item)
      return vim.list_contains(M.themes, item.text)
    end,
  })
end

--- A lualine theme for the current colorscheme with no backgrounds: the mode
--- section shows the mode colour as bold text instead of a solid block.
--- A function, so lualine rebuilds it on every theme change.
function M.lualine()
  local theme = require("lualine.utils.loader").load_theme("auto")
  for mode, sections in pairs(theme) do
    for name, section in pairs(sections) do
      if (name == "a" or name == "z") and mode ~= "inactive" then
        section.fg, section.gui = section.bg or section.fg, "bold"
      end
      section.bg = "NONE"
    end
  end
  return theme
end

return M
