-- The Mix: one Curated theme with the editor's UI from one theme and the
-- code's colours from another, as lua/config/themes.lua names them, applied as
-- the theme `converge` by converge.nvim. The config's own look (lua/theme.lua)
-- goes on top: the Mix's background and Mode colours come from its UI theme,
-- its Rainbow brackets from its syntax theme. See docs/converge-mix-design.md.
-- It also owns converge's Theme reads (`reading`, `snapshot`, `read`), for the
-- Mix and for leaving the light Added themes out (lua/curated_themes.lua).
local M = {}

-- The Mix as a theme's name: what `:colorscheme` applies, and what's saved.
M.name = "converge"

-- True during a Theme read, for the Mix or to find the light Added themes: the
-- theme hook (lua/theme.lua) ignores those, so nothing is saved or tinted.
M.reading = false

--- The Mix as lua/config/themes.lua's `mix` names it.
---@class MixConfig
---@field ui? string the Curated theme the editor's UI comes from
---@field syntax? string the Curated theme the code's colours come from
---@field overrides? { from?: table<string, string[]>, set?: table<string, table> }

--- The themes theme `name` draws its UI and its code's colours from: the
--- Mix's two halves, or `name` twice for any other theme.
---@param name string
---@return string ui
---@return string syntax
function M.halves(name)
  if name ~= M.name then
    return name, name
  end
  local recipe = M.recipe()
  return recipe.ui, recipe.syntax
end

--- converge's record of theme `name`'s colours with `background`, from a
--- Theme read: nil when it hasn't been read, false when it wouldn't load.
---@param name string
---@param background "dark"|"light"
---@return table|false|nil
function M.snapshot(name, background)
  return require("converge.snapshots").get(name, background, { capture = false })
end

--- A Theme read of each of `names`, with a dark background. Each applies its
--- theme for a moment: callers put the theme back.
---@param names string[]
function M.read(names)
  local snapshots = require("converge.snapshots")
  for _, name in ipairs(names) do
    snapshots.get(name, "dark", { capture = true })
  end
end

--- The Mix as converge's recipe: its UI and syntax themes, each a Curated
--- theme (a bad UI theme falls back to the default theme, a bad syntax theme
--- to the UI theme), and its overrides. The other slices follow the UI theme.
---@param mix? MixConfig default: lua/config/themes.lua's
---@return {ui: string, syntax: string, overrides?: table}
function M.recipe(mix)
  mix = mix or require("config.themes").mix
  local mixable = require("curated_themes").mixable
  local ui = mixable(mix.ui) and mix.ui or require("theme").default
  local syntax = mixable(mix.syntax) and mix.syntax or ui
  return { ui = ui, syntax = syntax, overrides = mix.overrides }
end

--- The Mix's name in the theme picker: its pair, and how many groups it overrides.
---@param mix? MixConfig default: lua/config/themes.lua's
---@return string
function M.label(mix)
  local recipe = M.recipe(mix)
  local overrides = recipe.overrides or {}
  local count = vim.tbl_count(overrides.set or {})
  for _, groups in pairs(overrides.from or {}) do
    count = count + #groups
  end
  local label = recipe.ui .. " + " .. recipe.syntax
  if count > 0 then
    label = ("%s · %d override%s"):format(label, count, count == 1 and "" or "s")
  end
  return label
end

-- Every attribute the config's own look can set: what a whole group brings,
-- taken `from` another theme or linked.
local every_attr = { "fg", "bg", "ctermbg", "italic", "underline", "reverse" }

--- What of highlight `group`'s `attrs` the config's own look replaces, e.g.
--- "bg (by the Tint)", or nil when nothing.
---@param group string
---@param attrs string[]
---@return string?
local function replaced(group, attrs)
  local theme = require("theme")
  local whole = theme.owner(group)
  if whole then
    return ("all of it (by %s)"):format(whole)
  end
  local parts = {}
  for _, attr in ipairs(attrs) do
    local owner = theme.owner(group, attr)
    if owner then
      table.insert(parts, ("%s (by %s)"):format(attr, owner))
    end
  end
  return #parts > 0 and table.concat(parts, ", ") or nil
end

--- What's wrong with `mix`, one message each: a theme that isn't a Curated
--- theme, and an override the config's own look replaces.
---@param mix? MixConfig default: lua/config/themes.lua's
---@return string[]
function M.problems(mix)
  mix = mix or require("config.themes").mix
  local recipe = M.recipe(mix)
  local problems = {}
  for _, slice in ipairs({ "ui", "syntax" }) do
    if recipe[slice] ~= mix[slice] then
      table.insert(
        problems,
        ("Mix: %s theme %s isn't a Curated theme, so %s is used"):format(slice, vim.inspect(mix[slice]), recipe[slice])
      )
    end
  end
  local overrides = mix.overrides or {}
  local set = overrides.set or {}
  for _, group in ipairs(vim.fn.sort(vim.tbl_keys(set))) do
    local attrs = set[group].link and every_attr or vim.fn.sort(vim.tbl_keys(set[group]))
    local what = replaced(group, attrs)
    if what then
      table.insert(problems, ("Mix: overrides.set.%s is replaced: %s"):format(group, what))
    end
  end
  for _, from in ipairs(vim.fn.sort(vim.tbl_keys(overrides.from or {}))) do
    if not require("curated_themes").mixable(from) then
      table.insert(problems, ("Mix: overrides.from names %s, which isn't a Curated theme"):format(vim.inspect(from)))
    end
    for _, group in ipairs(overrides.from[from]) do
      local what = replaced(group, every_attr)
      if what then
        table.insert(problems, ("Mix: overrides.from.%s's %s is replaced: %s"):format(from, group, what))
      end
    end
  end
  return problems
end

--- Forget converge's copies of the themes named `prefix…` (a Theme family's),
--- so the Mix reads them again with the family's new options: converge only
--- notices a theme's files changing, not its setup().
---@param prefix string
function M.forget(prefix)
  local dir = require("converge.cache").dir()
  for _, file in ipairs(vim.fn.glob(dir .. "/" .. prefix .. "*", false, true)) do
    vim.fn.delete(file)
  end
  require("converge.snapshots").clear()
end

--- converge.nvim's setup, when it loads: the Mix's recipe, no `:Converge`
--- (its picker saves a recipe that would win over the config's, so that's
--- deleted too), and its reads of themes marked (`M.reading`).
function M.setup()
  pcall(vim.api.nvim_del_user_command, "Converge")
  require("converge.store").delete()
  local capture = require("converge.capture")
  local read = capture.capture
  capture.capture = function(...)
    M.reading = true
    local ok, snap, err = pcall(read, ...)
    M.reading = false
    if not ok then
      error(snap, 0)
    end
    return snap, err
  end
  require("converge").setup({ recipe = M.recipe() })
end

return M
