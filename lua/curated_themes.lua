-- The Curated themes: the dark themes the theme picker offers. The built-in
-- ones, the Added themes (every dark theme the plugins named in `added` in
-- lua/config/themes.lua ship, found by a Theme read), and the Mix.
local M = {}

---@alias AddedEntry string|{ [1]: string, variants?: string[], opts?: table, dir?: string }
--- lua/config/themes.lua's `added`: a pasted repo, or a table narrowing it to
--- some `variants` or passing `opts` to its setup().
---@alias Added AddedEntry[]

-- The built-in Curated themes, each a Theme family's.
M.built_in = {
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha",
  "tokyonight-night",
  "tokyonight-storm",
  "tokyonight-moon",
}

--- Each entry of `added` as a table, as themes.lua's tables are: a pasted repo
--- string becomes `{ repo }`. Copies, so callers may change them.
---@param added? Added default: lua/config/themes.lua's
---@return table[]
local function as_entries(added)
  return vim.tbl_map(function(entry)
    return type(entry) == "string" and { entry } or vim.deepcopy(entry)
  end, added or require("config.themes").added)
end

--- Each entry of `added` as a lazy.nvim spec: lazy-loaded, which `:colorscheme`
--- does, with `variants` left out.
---@param added? Added default: lua/config/themes.lua's
---@return table[]
function M.specs(added)
  return vim.tbl_map(function(spec)
    spec.lazy, spec.variants = true, nil
    return spec
  end, as_entries(added))
end

--- The themes `added` ships: every one in each plugin's colors/ folder, or
--- those its `variants` names.
---@param added? Added default: lua/config/themes.lua's
---@return string[]
local function shipped(added)
  local names = {}
  for _, spec in ipairs(as_entries(added)) do
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

--- Whether the Theme read of `name` found it dark: nil when it hasn't been
--- read yet, false when it's light or wouldn't load. Light is a light
--- 'background', or a light editor background: some light themes
--- (kanagawa-lotus, onelight) leave 'background' as it was.
---@param name string
---@return boolean?
local function is_dark(name)
  local snap = require("mix").snapshot(name, "dark")
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
  return require("theme").lightness(("#%06x"):format(bg)) < 0.5
end

--- The Added themes: those `added` ships that a Theme read found dark.
---@param added? Added default: lua/config/themes.lua's
---@return string[]
function M.added(added)
  return vim.tbl_filter(function(name)
    return is_dark(name) == true
  end, shipped(added))
end

--- Every Curated theme: the built-in ones, the Added themes, and the Mix.
---@param added? Added default: lua/config/themes.lua's
---@return string[]
function M.list(added)
  local list = vim.list_extend(vim.deepcopy(M.built_in), M.added(added))
  table.insert(list, require("mix").name)
  return list
end

--- Whether the Mix can take a half from theme `name`: a Curated theme other
--- than the Mix itself, counting an added one not read yet.
---@param name any
---@param added? Added default: lua/config/themes.lua's
---@return boolean
function M.mixable(name, added)
  return vim.list_contains(M.built_in, name) or (vim.list_contains(shipped(added), name) and is_dark(name) ~= false)
end

--- A Theme read of every theme `added` ships that hasn't been read, to leave
--- out the light ones. Each read applies its theme for a moment, so the theme
--- and background are put back after, unsaved. Nothing is drawn meanwhile: the
--- reads skip Transparency, so a redraw would show each theme's background.
---@param added? Added default: lua/config/themes.lua's
function M.read_added(added)
  local unread = vim.tbl_filter(function(name)
    return is_dark(name) == nil
  end, shipped(added))
  if #unread == 0 then
    return
  end
  local current, background = vim.g.colors_name, vim.o.background
  require("theme").without_redraws(function()
    require("mix").read(unread)
    -- With no theme named, setting the background reloads none.
    vim.g.colors_name = nil
    vim.o.background = background
    if current then
      require("theme").apply_unsaved(current)
    end
  end)
end

return M
