-- Theme italics: which syntax each theme family draws in italics, chosen per
-- family from a picker (<leader>uy) that re-applies the theme on each change,
-- and the Extra italics: syntax made italic on every theme, chosen once in the
-- same picker. Saved in theme.json beside the theme and tint (lua/theme.lua).
-- The line diagnostics and Breadcrumbs are italic whatever the theme, so
-- they're not here.
local M = {}

local icons = require("util.icons")

-- Each family's italic options, in its own order, with its defaults, and how
-- it spells "italic" and "not italic" in its `styles`. "Not italic" must
-- replace the default when the themes merge it: tokyonight merges maps, so an
-- empty one would keep a default italic.
local families = {
  tokyonight = {
    plugin = "tokyonight.nvim",
    options = { "comments", "keywords", "functions", "variables" },
    defaults = { comments = true, keywords = true },
    style = function(on)
      return { italic = on }
    end,
  },
  catppuccin = {
    plugin = "catppuccin",
    options = {
      "comments",
      "conditionals",
      "loops",
      "functions",
      "keywords",
      "strings",
      "variables",
      "numbers",
      "booleans",
      "properties",
      "types",
      "operators",
    },
    defaults = { comments = true, conditionals = true },
    style = function(on)
      return on and { "italic" } or {}
    end,
  },
}

-- Extra italics: Syntax types made italic by this config rather than the
-- theme, chosen once for every theme. Each covers its highlight names and
-- their deeper ones (`@variable.parameter.lua`), unless another lists a
-- deeper one itself (`@function.builtin` is a built-in, not a function).
local extras = {
  { name = "parameters", groups = { "@variable.parameter", "@variable.parameter.builtin" } },
}

--- The family of the current theme, if it has italic options.
local function current_family()
  local family = (vim.g.colors_name or ""):match("^(%a+)")
  return families[family] and family or nil
end

--- Which of `family`'s options are italic: the saved choice, else its default.
---@return table<string, boolean>
local function chosen(family)
  local saved = (require("theme").saved().italics or {})[family] or {}
  local ret = {}
  for _, option in ipairs(families[family].options) do
    local value = saved[option]
    if type(value) == "boolean" then
      ret[option] = value
    else
      ret[option] = families[family].defaults[option] == true
    end
  end
  return ret
end

--- `family`'s `styles` for its chosen italics, to merge into its opts.
function M.styles(family)
  local ret = {}
  for option, on in pairs(chosen(family)) do
    ret[option] = families[family].style(on)
  end
  return ret
end

--- Which Extra italics are on: the saved choice, else off.
---@return table<string, boolean>
local function chosen_extras()
  local saved = require("theme").saved().extra_italics
  return type(saved) == "table" and saved or {}
end

--- The highlight name in `extras` that `name` is, or is the deepest under.
---@return {name: string, groups: string[]}?
local function owner(name)
  local best, depth
  for _, extra in ipairs(extras) do
    for _, group in ipairs(extra.groups) do
      if (name == group or vim.startswith(name, group .. ".")) and #group > (depth or 0) then
        best, depth = extra, #group
      end
    end
  end
  return best
end

--- Make every highlight an Extra italic that's on covers italic, keeping the
--- rest of its style. Run after every theme change (lua/theme.lua).
function M.apply_extras()
  local on = chosen_extras()
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local extra = owner(name)
    if extra and on[extra.name] == true then
      local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
      -- A `default` definition never replaces an existing one, so drop the flag.
      hl.italic, hl.default = true, nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

--- Set up `family` again with its chosen italics (if the theme has a family),
--- and re-apply the theme.
local function reload(family)
  if family then
    local opts = LazyVim.opts(families[family].plugin)
    opts.styles = vim.tbl_extend("force", opts.styles or {}, M.styles(family))
    require(family).setup(opts)
  end
  vim.cmd.colorscheme(vim.g.colors_name)
end

--- Pick an option to flip; the list reopens after each, until closed.
function M.pick()
  local family = current_family()
  local choice = family and chosen(family) or {}
  local on = chosen_extras()
  local rows = {}
  for _, option in ipairs(family and families[family].options or {}) do
    table.insert(rows, { option = option })
  end
  for _, extra in ipairs(extras) do
    table.insert(rows, { extra = extra.name })
  end
  vim.ui.select(rows, {
    prompt = "Italics: " .. (family or "extra"),
    format_item = function(row)
      local is_on = row.extra and on[row.extra] or choice[row.option]
      return (is_on and icons.ui.Check or icons.ui.Close) .. "  " .. (row.extra or row.option)
    end,
  }, function(row)
    if not row then
      return
    end
    if row.extra then
      on[row.extra] = not on[row.extra]
      require("theme").save({ extra_italics = on })
    else
      choice[row.option] = not choice[row.option]
      local italics = require("theme").saved().italics or {}
      italics[assert(family)] = choice -- theme rows only exist for a family
      require("theme").save({ italics = italics })
    end
    reload(family)
    vim.schedule(M.pick)
  end)
end

return M
