-- Themes: the Curated themes (built in, added in lua/config/themes.lua, and
-- the Mix), persistence, Transparency and the Tint. Every theme change,
-- however it happens (the picker, `:colorscheme`), goes through one
-- ColorScheme hook (but for converge's reads of themes, lua/mix.lua), which:
--   1. records the theme's own editor background (`M.background`; on the Mix,
--      its UI theme's, as are the Mode colours, while the brackets are its
--      syntax theme's),
--   2. gives modes.nvim the theme's mode colours, and the background to fade
--      them over,
--   3. tints the "where am I" lines: the tint colour faded over that background,
--   4. colours the Rainbow brackets, and the Block guide with them, from the
--      theme's yellow, purple and blue,
--   5. makes the reference highlights (other occurrences of the word under
--      the cursor) underlines with no background,
--   6. saves the theme so the next start restores it (live previews in the
--      picker and the theme applied at startup aren't saved),
--   7. clears the background of whatever the themes' native transparency
--      options leave solid (all of it, on an added theme), so the terminal's
--      glass shows through: at once, so no frame shows the theme's background,
--      and again once plugins have redefined theirs,
--   8. makes the line diagnostics and the Breadcrumbs italic, and applies the
--      Extra italics (lua/theme_italics.lua).
local M = {}

-- The built-in Curated themes: the Theme families'. The picker also offers the
-- dark themes of the plugins added in lua/config/themes.lua, and the Mix
-- (`converge`, lua/mix.lua); see `M.curated`.
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

--- Each entry of `added` (lua/config/themes.lua's, by default) as a table:
--- a pasted repo string becomes `{ repo }`. Copies, so callers may change them.
---@param added? (string|table)[]
---@return table[]
local function as_specs(added)
  return vim.tbl_map(function(entry)
    return type(entry) == "string" and { entry } or vim.deepcopy(entry)
  end, added or require("config.themes").added)
end

--- Each entry of `added` (lua/config/themes.lua's, by default) as a lazy.nvim
--- spec: lazy-loaded, which `:colorscheme` does, with `variants` left out.
---@param added? (string|table)[]
---@return table[]
function M.added_specs(added)
  return vim.tbl_map(function(spec)
    spec.lazy, spec.variants = true, nil
    return spec
  end, as_specs(added))
end

--- The themes `added` ships: every one in each plugin's colors/ folder, or
--- those its `variants` names.
---@param added? (string|table)[]
---@return string[]
local function added_names(added)
  local names = {}
  for _, spec in ipairs(as_specs(added)) do
    local dir = spec.dir and vim.fs.normalize(spec.dir)
    if not dir then
      for _, plugin in pairs(require("lazy.core.config").plugins) do
        if plugin[1] == spec[1] then
          dir = plugin.dir
        end
      end
    end
    for _, file in ipairs(dir and vim.fn.glob(dir .. "/colors/*", false, true) or {}) do
      local name, ext = vim.fn.fnamemodify(file, ":t:r"), vim.fn.fnamemodify(file, ":e")
      if (ext == "lua" or ext == "vim") and (not spec.variants or vim.list_contains(spec.variants, name)) then
        table.insert(names, name)
      end
    end
  end
  return names
end

--- The red, green and blue of "#rrggbb", 0 to 255 each.
local function channels(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

--- Whether converge's read of theme `name` found it dark: nil when it hasn't
--- read it yet, false when it's light or wouldn't load. Light is a light
--- 'background', or a light editor background: some light themes
--- (kanagawa-lotus, onelight) leave 'background' as it was.
---@return boolean?
local function is_dark(name)
  local snap = require("converge.snapshots").get(name, "dark", { capture = false })
  if snap == nil then
    return nil
  end
  if snap == false or snap.background ~= "dark" then
    return false
  end
  local bg = (snap.groups.Normal or {}).bg
  if not bg then
    return true
  end
  -- Perceived lightness, 0 to 1.
  local r, g, b = channels(("#%06x"):format(bg))
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 < 0.5
end

--- The Curated themes: the built-in ones, the added ones read and found dark,
--- and the Mix.
---@param added? (string|table)[] default: lua/config/themes.lua's
---@return string[]
function M.curated(added)
  local list = vim.deepcopy(M.themes)
  for _, name in ipairs(added_names(added)) do
    if is_dark(name) then
      table.insert(list, name)
    end
  end
  table.insert(list, "converge")
  return list
end

--- Whether `name` is a Curated theme other than the Mix, counting an added one
--- not read yet.
---@param name any
---@param added? (string|table)[] default: lua/config/themes.lua's
---@return boolean
function M.is_curated(name, added)
  return vim.list_contains(M.themes, name) or (vim.list_contains(added_names(added), name) and is_dark(name) ~= false)
end

-- True while startup applies the saved theme (or a fallback), which is never saved.
local restoring = false

--- Have converge read every added theme it hasn't, to find the light ones.
--- Each read applies its theme for a moment, so the theme and background are
--- put back after, unsaved. Nothing is drawn meanwhile: the reads skip
--- Transparency, so a frame would show each theme's background.
---@param added? (string|table)[] default: lua/config/themes.lua's
function M.detect(added)
  local unread = vim.tbl_filter(function(name)
    return is_dark(name) == nil
  end, added_names(added))
  if #unread == 0 then
    return
  end
  local current, background = vim.g.colors_name, vim.o.background
  -- `vim.cmd` caches each command's function in itself, so putting back what
  -- was there (nil, usually) brings :redraw back.
  local redraw, lazyredraw = rawget(vim.cmd, "redraw"), vim.o.lazyredraw
  vim.cmd.redraw, vim.o.lazyredraw = function() end, true
  local ok, err = pcall(function()
    local snapshots = require("converge.snapshots")
    for _, name in ipairs(unread) do
      snapshots.get(name, "dark", { capture = true })
    end
    -- With no theme named, setting the background reloads none.
    vim.g.colors_name = nil
    vim.o.background = background
    if current then
      restoring = true
      pcall(vim.cmd.colorscheme, current)
      restoring = false
    end
  end)
  vim.cmd.redraw, vim.o.lazyredraw = redraw, lazyredraw
  if not ok then
    error(err, 0)
  end
end

-- The tint colour, and how much of it shows over the theme's background (0 to
-- 1). Used when nothing valid is saved; `:Tint` changes it.
M.default_tint = { color = "#ffffff", fade = 0.1 }

-- The Mode colours' groups: modes.nvim's, then normal and command, which only
-- the mode-coloured line number uses (lua/line_number.lua).
local mode_groups = {
  insert = "ModesInsert",
  visual = "ModesVisual",
  delete = "ModesDelete",
  copy = "ModesCopy",
  normal = "ModesNormal",
  command = "ModesCommand",
}

-- What the tint colours: the cursor line (and its gutter), the Explorer's line
-- and the selected completion item.
local tinted = { "CursorLine", "CursorLineNr", "CursorLineSign", "NeoTreeCursorLine", "BlinkCmpMenuSelection" }

-- The tinted groups in the cursor line's gutter, and whether they're tinted:
-- not while the Cursor line is off and its number shows alone
-- (lua/line_number.lua).
local gutter = { CursorLineNr = true, CursorLineSign = true }
M.gutter_tinted = true

-- The Rainbow brackets' groups, outermost first.
M.rainbow = { "RainbowBracket1", "RainbowBracket2", "RainbowBracket3" }

-- The Block guide's groups: the same colours, faded to `guide_fade` over the
-- theme's background, so a block's guide is a faint shade of its brackets.
M.guide = { "BlockGuide1", "BlockGuide2", "BlockGuide3" }
local guide_fade = 0.3

-- The reference highlights: other occurrences of the word under the cursor.
local references = { "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- The saved state, or an empty table when it's missing or unreadable.
---@return {theme?: string, tint?: {color: string, fade: number}, italics?: table<string, table<string, boolean>>, extra_italics?: table<string, boolean>, statusline_filename?: boolean} (the last only until migrated)
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

--- The saved state (theme, tint, Theme italics, Extra italics), for other theme modules.
M.saved = read_state

--- Merge `changes` into the saved state.
M.save = save_state

--- Whether a colorscheme picker is open, so theme changes are only previews.
local function previewing()
  return #Snacks.picker.get({ source = "colorschemes", tab = false }) > 0
end

-- What transparency clears: panel and float backgrounds, named or by prefix,
-- and the blocks drawn inside the text (see `in_text`).
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
    -- What added themes give a background that the Theme families don't: the
    -- git signs in the gutter, the completion menu's columns, inactive
    -- windows' gutter, the end of the buffer, Snacks' inactive winbar, the
    -- outline, terminal statuslines and the message separator.
    "GitSignsAdd",
    "GitSignsChange",
    "GitSignsDelete",
    "GitSignsTopdelete",
    "GitSignsChangedelete",
    "GitSignsUntracked",
    "PmenuKind",
    "PmenuExtra",
    "PmenuBorder",
    "SignColumnNC",
    "NonText",
    "SnacksWinBarNC",
    "AerialNormal",
    "StatusLineTerm",
    "StatusLineTermNC",
    "MsgSeparator",
  },
  prefixes = {
    "BlinkCmp",
    "BufferLine",
    "DiagnosticSign", -- the gutter's diagnostic signs
    "NeoTree",
    "NoiceCmdline",
    "NoiceConfirm",
    "NoiceLspProgress",
    "NoiceMini",
    "NoicePopup",
    "NoiceSplit",
    "DropBar",
    "Saga",
    "SnacksDashboard",
    "SnacksInput",
    "SnacksNotifier",
    "SnacksPicker",
    "WhichKey",
  },
  -- Blocks inside the text, by prefix: diagnostics at the end of a line, inlay
  -- hints, and Markdown heading bars, inline code and code blocks. They keep
  -- only their colour. Cleared even when they're links: render-markdown, which
  -- loads after the theme, links its groups to ones that keep a background
  -- (DiffAdd, ColorColumn).
  in_text = { "@markup.heading", "@markup.raw", "DiagnosticVirtualText", "LspInlayHint", "RenderMarkdown" },
  -- A float's Frame, by name: its border, title, footer and prompt, with the
  -- prompt's icon (not other icons: dropbar's, which-key's). Cleared even when
  -- they're links: noice links its cmdline popup's to the gutter's diagnostic
  -- signs, which some themes (kanagawa) give a background.
  frame = { "Border", "Title", "Footer", "Prompt", "CmdlineIcon", "InputIcon" },
  keep = { "Cursor", "Sel", "Visual", "Search", "Diff", "Thumb", "ScrollBar", "Scrollbar", "PickWin" },
}

--- Whether `name` starts with one of `prefixes`.
local function has_prefix(name, prefixes)
  return vim.iter(prefixes):any(function(prefix)
    return vim.startswith(name, prefix)
  end)
end

--- Whether `name` contains one of `words`.
local function has_word(name, words)
  return vim.iter(words):any(function(word)
    return name:find(word, 1, true) ~= nil
  end)
end

local function should_clear(name)
  local listed = vim.list_contains(transparency.groups, name)
    or has_prefix(name, transparency.prefixes)
    or has_prefix(name, transparency.in_text)
  return listed and not has_word(name, transparency.keep)
end

--- The group `name`'s links end at.
---@param name string
---@return string
local function link_target(name)
  for _ = 1, 20 do -- a theme could link in a loop
    local link = vim.api.nvim_get_hl(0, { name = name }).link
    if not link then
      break
    end
    name = link
  end
  return name
end

--- Clear the background of every group transparency covers. Linked groups are
--- left alone, to follow their target, except in-text ones (see `in_text`), and
--- panel backgrounds and Frame parts linked to a group that keeps one
--- (NeoTreeNormal to evergarden's Panel), which take their target's colours
--- instead. Other links (NeoTreePreview to Search) keep their accent, and links
--- to a group cleared here (noice's cmdline border to DiagnosticSignInfo) stay,
--- to follow what's done to it next (the italics).
local function make_transparent()
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if hl.link and should_clear(name) then
      local target = vim.api.nvim_get_hl(0, { name = name, link = false })
      local keeps_bg = (target.bg or target.ctermbg) and not should_clear(link_target(name))
      local panel_or_frame = keeps_bg and (name:find("Normal", 1, true) or has_word(name, transparency.frame))
      if panel_or_frame or has_prefix(name, transparency.in_text) then
        hl = target
      end
    end
    if not hl.link and (hl.bg or hl.ctermbg) and should_clear(name) then
      -- A `default` definition never replaces an existing one, so drop the flag.
      hl.bg, hl.ctermbg, hl.default = nil, nil, nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

-- What's italic whatever the theme: the diagnostics at the end of a line, and
-- the Breadcrumbs' text, by name or prefix.
local italic = {
  groups = { "WinBar", "WinBarNC" },
  prefixes = { "DiagnosticVirtualText", "DropBarKind" },
}

--- Make every group `italic` covers italic, keeping the rest of its style.
local function italicise()
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    if vim.list_contains(italic.groups, name) or has_prefix(name, italic.prefixes) then
      local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
      hl.italic, hl.default = true, nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

--- Restyle what plugins define for the new theme: transparency, then italics,
--- then the Extra italics (lua/theme_italics.lua).
local function restyle()
  make_transparent()
  italicise()
  require("theme_italics").apply_extras()
end

-- Other themes' Mode colours: each from a group's foreground.
local mode_sources = {
  insert = "String",
  visual = "Keyword",
  delete = "DiagnosticError",
  copy = "DiagnosticWarn",
  normal = "Function",
  command = "Constant",
}

-- Other themes' nearest yellow, purple and blue, for the Rainbow brackets.
local rainbow_fallback = { "DiagnosticWarn", "Keyword", "Function" }

--- Theme `name`'s highlight groups, links followed: the live ones when it's
--- the theme applied (read before Transparency clears them), else converge's
--- copy of it (the Mix's halves).
---@param name string
---@return fun(group: string): table
local function groups_of(name)
  if name == vim.g.colors_name then
    return function(group)
      return vim.api.nvim_get_hl(0, { name = group, link = false })
    end
  end
  local snap = require("converge.snapshots").get(name, vim.o.background, { capture = false })
  return function(group)
    return snap and snap.groups[group] or {}
  end
end

--- `value` (a colour number) as "#rrggbb".
local function hex(value)
  return value and ("#%06x"):format(value)
end

--- Theme `name`'s own editor background, Mode colours and Rainbow brackets, as
--- "#rrggbb". The Theme families' native transparency has already cleared
--- Normal, so theirs come from their palette; any other theme's are read from
--- its own groups, and a colour it doesn't have is left out (modes.nvim's own
--- is used). Normal and command match the statusline's mode section.
---@param name string
---@return {bg?: string, insert?: string, visual?: string, delete?: string, copy?: string, normal?: string, command?: string, rainbow?: string[]}
local function palette_of(name)
  local style = name:match("^tokyonight%-(%a+)$")
  if style then
    local c = require("tokyonight.colors").setup({ style = style })
    return {
      bg = c.bg,
      insert = c.green,
      visual = c.magenta,
      delete = c.red,
      copy = c.yellow,
      normal = c.blue,
      command = c.yellow,
      rainbow = { c.yellow, c.magenta, c.blue },
    }
  end
  local flavour = name:match("^catppuccin%-?(%a*)$")
  if flavour then
    local c = require("catppuccin.palettes").get_palette(flavour ~= "" and flavour or nil)
    return {
      bg = c.base,
      insert = c.green,
      visual = c.mauve,
      delete = c.red,
      copy = c.yellow,
      normal = c.blue,
      command = c.peach,
      rainbow = { c.yellow, c.mauve, c.blue },
    }
  end
  local get = groups_of(name)
  local palette = {}
  -- A theme with its own transparency on clears Normal: try its floats and menus.
  for _, group in ipairs({ "Normal", "NormalFloat", "Pmenu" }) do
    palette.bg = palette.bg or hex(get(group).bg)
  end
  for mode, group in pairs(mode_sources) do
    palette[mode] = hex(get(group).fg)
  end
  local rainbow = {}
  for i, group in ipairs(rainbow_fallback) do
    rainbow[i] = hex(get(group).fg)
  end
  palette.rainbow = rainbow[1] and rainbow[2] and rainbow[3] and rainbow or nil
  return palette
end

--- The current theme's palette (see `palette_of`). On the Mix, the background
--- and Mode colours are its UI theme's, the Rainbow brackets its syntax theme's.
local function theme_palette()
  local name = vim.g.colors_name or ""
  local ui, syntax = name, name
  if name == "converge" then
    local recipe = require("mix").recipe()
    ui, syntax = recipe.ui, recipe.syntax
  end
  local palette = palette_of(ui)
  palette.rainbow = palette_of(syntax).rainbow
  return palette
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
function M.blend(color, base, alpha)
  local c, b, mixed = { channels(color) }, { channels(base) }, {}
  for i = 1, 3 do
    mixed[i] = math.floor(alpha * c[i] + (1 - alpha) * b[i] + 0.5)
  end
  return ("#%02x%02x%02x"):format(unpack(mixed))
end

--- The global definition of `name`, links followed. Not `link = false` alone:
--- for a built-in group that gives what the current window's 'winhighlight'
--- puts in its place (modes.nvim's groups, outside normal mode).
---@param name string
---@return table
function M.get_hl(name)
  local hl = vim.api.nvim_get_hl(0, { name = name })
  return hl.link and vim.api.nvim_get_hl(0, { name = name, link = false }) or hl
end

--- Give every tinted group the tint faded over the theme's background.
local function apply_tint()
  local bg = M.blend(M.tint.color, M.background or "#000000", M.tint.fade)
  for _, name in ipairs(tinted) do
    local hl = M.get_hl(name)
    hl.bg = (M.gutter_tinted or not gutter[name]) and bg or nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

M.apply_tint = apply_tint

--- Colour the Rainbow brackets from `colors` (yellow, purple, blue), or link
--- them to the groups they'd come from when the theme lacks one, and the Block
--- guide with the same colours faded.
---@param colors? string[]
local function apply_rainbow(colors)
  for i, name in ipairs(M.rainbow) do
    vim.api.nvim_set_hl(0, name, colors and { fg = colors[i] } or { link = rainbow_fallback[i] })
    local fg = colors and colors[i] or hex(vim.api.nvim_get_hl(0, { name = rainbow_fallback[i], link = false }).fg)
    vim.api.nvim_set_hl(
      0,
      M.guide[i],
      fg and { fg = M.blend(fg, M.background or "#000000", guide_fade) } or { link = "NonText" }
    )
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

--- What sets `attr` of highlight `group` whatever the theme says, by name, or
--- nil when nothing does. With no `attr`: what sets the whole group.
---@param group string
---@param attr? string
---@return string?
function M.owner(group, attr)
  if vim.list_contains(vim.tbl_values(mode_groups), group) then
    return "the Mode colours"
  elseif vim.list_contains(M.rainbow, group) then
    return "the Rainbow brackets"
  elseif vim.list_contains(M.guide, group) then
    return "the Block guide"
  elseif attr == "bg" and vim.list_contains(tinted, group) then
    return "the Tint"
  elseif
    vim.list_contains({ "bg", "ctermbg", "reverse", "underline" }, attr) and vim.list_contains(references, group)
  then
    return "the Reference highlights"
  elseif vim.list_contains({ "bg", "ctermbg" }, attr) and should_clear(group) then
    return "Transparency"
  elseif attr == "italic" and (vim.list_contains(italic.groups, group) or has_prefix(group, italic.prefixes)) then
    return "the line diagnostics' and Breadcrumbs' italics"
  end
end

--- The hook that runs on every theme change.
local function on_change(args)
  -- converge reading a theme for the Mix, or to find light ones: not a change.
  -- Nor is Transparency applied: converge would record the theme cleared.
  if require("mix").reading then
    return
  end
  -- Name the theme as it was chosen, so it's read, saved and restored as
  -- itself: palenight doesn't name itself, and kanagawa-dragon and
  -- evergarden-spring name themselves after their family. Not the Mix, which
  -- names itself once converge has read its themes, a tick later.
  local name = vim.g.colors_name
  if args.match ~= "" and (not name or vim.startswith(args.match, name .. "-")) then
    vim.g.colors_name = args.match
  end
  local palette = theme_palette()
  M.background = palette.bg
  -- modes.nvim's own ColorScheme hook, which runs after this one, reads its
  -- colours from these groups.
  for mode, group in pairs(mode_groups) do
    if palette[mode] then
      vim.api.nvim_set_hl(0, group, { bg = palette[mode] })
    end
  end
  apply_tint()
  apply_rainbow(palette.rainbow)
  underline_references()
  -- Now, once the theme's own background is read above, so no frame shows it
  -- (the Theme families' options already cleared theirs; added themes' haven't).
  make_transparent()
  if not (restoring or previewing()) then
    save_state({ theme = vim.g.colors_name })
  end
  -- Scheduled, to run after plugins (bufferline, lualine, …) redefine their
  -- highlights for the new theme.
  vim.schedule(restyle)
end

-- True while a restyle for plugins that just loaded waits for the next tick.
local restyle_pending = false

--- `restyle` once on the next tick, however many plugins load before it
--- (some 70 at startup).
local function restyle_late()
  if restyle_pending then
    return
  end
  restyle_pending = true
  vim.schedule(function()
    restyle_pending = false
    restyle()
  end)
end

--- LazyVim's `colorscheme` option: set up the change hook, then apply the
--- saved theme, falling back to the default.
function M.load()
  local state = read_state()
  -- The filename toggle used to be saved here: move it to the toggle state, so
  -- that :ToggleStateReset can't bring the old value back.
  local toggles = require("toggle_state")
  if state.statusline_filename ~= nil then
    if not toggles.has("ui.statusline_filename") then
      toggles.set("ui.statusline_filename", state.statusline_filename ~= false)
    end
    state.statusline_filename = nil
    vim.fn.writefile({ vim.json.encode(state) }, state_file)
  end
  local tint = state.tint
  M.tint = type(tint) == "table" and valid_color(tint.color) and valid_fade(tint.fade) and tint or M.default_tint
  vim.api.nvim_create_user_command("Tint", function(cmd)
    M.set_tint(unpack(cmd.fargs))
  end, { nargs = "*", desc = "Tint the cursor line: :Tint <#rrggbb> <fade 0-1>" })

  local group = vim.api.nvim_create_augroup("theme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = on_change })
  -- Plugins that load after the theme (lualine and noice at VeryLazy, the
  -- notifier on the first notification, blink on the first insert) define
  -- their highlights then: restyle those too.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "LazyLoad", "VeryLazy" },
    callback = restyle_late,
  })
  -- Scheduled, so it also covers LazyVim's own fallback (habamax) should the default fail too.
  restoring = true
  vim.schedule(function()
    restoring = false
  end)
  local saved = state.theme
  if not (type(saved) == "string" and pcall(vim.cmd.colorscheme, saved)) then
    vim.cmd.colorscheme(M.default)
  end
  -- What's wrong with the Mix in lua/config/themes.lua, once the notifier is up.
  vim.schedule(function()
    for _, problem in ipairs(require("mix").problems()) do
      vim.notify(problem, vim.log.levels.WARN, { title = "Mix" })
    end
  end)
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

--- The current theme's colour for `mode` (the Mode colours), as "#rrggbb":
--- from its palette for the curated themes, else modes.nvim's own (and none
--- for normal and command).
---@param mode "insert"|"visual"|"delete"|"copy"|"normal"|"command"
---@return string?
function M.mode_color(mode)
  local bg = vim.api.nvim_get_hl(0, { name = mode_groups[mode], link = false }).bg
  return bg and ("#%06x"):format(bg)
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
  -- No redraws while Normal is solid: modes.nvim's setup redraws, which would
  -- flash the theme's background over the glass at startup. `vim.cmd` caches
  -- each command's function in itself, so clearing the stub brings it back.
  vim.cmd.redraw = function() end
  local ok, err = pcall(setup)
  vim.cmd.redraw = nil
  restore_normal()
  if not ok then
    error(err, 0)
  end
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = restore_normal })
end

--- A colorscheme picker, with live preview, limited to the Curated themes.
--- Added themes not read yet are read first, to leave out the light ones.
function M.pick()
  M.detect()
  local curated = M.curated()
  Snacks.picker.colorschemes({
    transform = function(item)
      return vim.list_contains(curated, item.text)
    end,
    -- The Mix by what's in it; picking it still applies `converge`.
    format = function(item)
      return { { item.text == "converge" and require("mix").label() or item.text } }
    end,
  })
end

--- A lualine theme for the current colorscheme with no backgrounds: the mode
--- section shows the mode colour as bold text instead of a solid block, and
--- every other section the theme's soft foreground, whatever the mode.
--- A function, so lualine rebuilds it on every theme change.
function M.lualine()
  -- A copy: a theme that ships its own lualine theme (oasis, evergarden)
  -- returns the same table each time, which the next change would restyle again.
  local theme = vim.deepcopy(require("lualine.utils.loader").load_theme("auto"))
  local soft = theme.normal.c.fg
  -- Each section once: some themes share them between modes (evergarden's
  -- command mode is its normal mode), and a second pass would lose the colour.
  -- The active modes first, so a section shared with inactive is styled as theirs.
  local seen = {}
  local modes = vim.tbl_keys(theme)
  table.sort(modes, function(a, b)
    return (a == "inactive" and 1 or 0) < (b == "inactive" and 1 or 0)
  end)
  for _, mode in ipairs(modes) do
    for name, section in pairs(theme[mode]) do
      if not seen[section] then
        seen[section] = true
        if mode ~= "inactive" then
          if name == "a" then
            section.fg, section.gui = section.bg or section.fg, "bold"
          else
            section.fg, section.gui = soft, nil
          end
        end
        section.bg = "NONE"
      end
    end
  end
  return theme
end

return M
