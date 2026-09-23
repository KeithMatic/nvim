-- Themes: the curated list of dark themes, persistence and transparency. Every
-- theme change, however it happens (the picker, `:colorscheme`), goes through
-- one ColorScheme hook, which:
--   1. records the theme's own editor background (`M.background`),
--   2. saves the theme so the next start restores it (live previews in the
--      picker and the theme applied at startup aren't saved),
--   3. clears the background of whatever the themes' native transparency
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

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- The saved state, or an empty table when it's missing or unreadable.
---@return {theme?: string}
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
      hl.bg, hl.ctermbg = nil, nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

--- The current theme's own editor background, as "#rrggbb". The curated
--- themes' native transparency has already cleared Normal, so theirs comes
--- from their palette.
---@return string?
local function theme_background()
  local name = vim.g.colors_name or ""
  local style = name:match("^tokyonight%-(%a+)$")
  if style then
    return require("tokyonight.colors").setup({ style = style }).bg
  end
  local flavour = name:match("^catppuccin%-?(%a*)$")
  if flavour then
    return require("catppuccin.palettes").get_palette(flavour ~= "" and flavour or nil).base
  end
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  return bg and ("#%06x"):format(bg)
end

--- The hook that runs on every theme change.
local function on_change()
  M.background = theme_background()
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
