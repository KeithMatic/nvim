-- The Mix: one Curated theme with the editor's UI from one theme and the
-- code's colours from another, as lua/config/themes.lua names them, applied as
-- the theme `converge` by converge.nvim. The config's own look (lua/theme.lua)
-- goes on top: the Mix's background and Mode colours come from its UI theme,
-- its Rainbow brackets from its syntax theme. See docs/converge-mix-design.md.
local M = {}

-- True while converge reads a theme, for the Mix or to find light ones: the
-- theme hook (lua/theme.lua) ignores those, so nothing is saved or tinted.
M.reading = false

--- The Mix as converge's recipe: its UI and syntax themes, each a Curated
--- theme (a bad UI theme falls back to the default theme, a bad syntax theme
--- to the UI theme), and its overrides. The other slices follow the UI theme.
---@param mix? {ui?: string, syntax?: string, overrides?: table} default: lua/config/themes.lua's
---@return {ui: string, syntax: string, overrides?: table}
function M.recipe(mix)
  mix = mix or require("config.themes").mix
  local theme = require("theme")
  local ui = theme.is_curated(mix.ui) and mix.ui or theme.default
  local syntax = theme.is_curated(mix.syntax) and mix.syntax or ui
  return { ui = ui, syntax = syntax, overrides = mix.overrides }
end

--- The Mix's name in the theme picker: its pair, and how many groups it overrides.
---@return string
function M.label()
  local recipe = M.recipe()
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

--- What's wrong with `mix`, one message each: a theme that isn't a Curated
--- theme, and an override the config's own look replaces.
---@param mix? {ui?: string, syntax?: string, overrides?: table} default: lua/config/themes.lua's
---@return string[]
function M.problems(mix)
  mix = mix or require("config.themes").mix
  local theme, recipe = require("theme"), M.recipe(mix)
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
    local replaced = {}
    for _, attr in ipairs(vim.fn.sort(vim.tbl_keys(set[group]))) do
      local owner = theme.owner(group, attr)
      if owner then
        table.insert(replaced, ("%s (by %s)"):format(attr, owner))
      end
    end
    if #replaced > 0 then
      table.insert(problems, ("Mix: overrides.set.%s is replaced: %s"):format(group, table.concat(replaced, ", ")))
    end
  end
  for _, from in ipairs(vim.fn.sort(vim.tbl_keys(overrides.from or {}))) do
    for _, group in ipairs(overrides.from[from]) do
      local owner = theme.owner(group)
      if owner then
        table.insert(problems, ("Mix: overrides.from.%s's %s is replaced by %s"):format(from, group, owner))
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
