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
-- One named like an option the current family offers is hidden, and left to
-- the theme.
local extras = {
  { name = "comments", groups = { "Comment", "@comment" } },
  {
    name = "documentation",
    label = "documentation comments",
    groups = { "@comment.documentation", "@string.documentation" },
  },
  { name = "keywords", groups = { "Keyword", "Statement", "@keyword", "@keyword.function" } },
  { name = "conditionals", groups = { "Conditional", "@keyword.conditional", "@keyword.conditional.ternary" } },
  { name = "loops", groups = { "Repeat", "@keyword.repeat" } },
  {
    name = "returns",
    label = "return and exception keywords",
    groups = { "@keyword.return", "@keyword.exception", "Exception" },
  },
  { name = "imports", groups = { "Include", "@keyword.import" } },
  { name = "functions", groups = { "Function", "@function", "@function.call" } },
  { name = "methods", groups = { "@function.method", "@function.method.call" } },
  { name = "variables", groups = { "Identifier", "@variable" } },
  { name = "parameters", groups = { "@variable.parameter", "@variable.parameter.builtin" } },
  { name = "properties", groups = { "@property", "@variable.member" } },
  {
    name = "builtins",
    label = "built-ins (self, this)",
    groups = { "@variable.builtin", "@function.builtin", "@type.builtin", "@constant.builtin", "@module.builtin" },
  },
  { name = "types", groups = { "Type", "@type", "@type.definition" } },
  { name = "constants", groups = { "Constant", "@constant", "@constant.macro" } },
  { name = "modules", groups = { "@module" } },
  { name = "decorators", groups = { "@attribute", "@attribute.builtin" } },
  { name = "strings", groups = { "String", "@string" } },
  {
    name = "characters",
    label = "characters and escapes",
    groups = { "Character", "@character", "@string.escape", "SpecialChar" },
  },
  { name = "numbers", groups = { "Number", "Float", "@number", "@number.float" } },
  { name = "booleans", groups = { "Boolean", "@boolean" } },
  { name = "operators", groups = { "Operator", "@operator", "@keyword.operator" } },
  { name = "tags", label = "markup tags and attributes", groups = { "@tag", "@tag.attribute" } },
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

--- The Extra italics shown for the current theme: those its family doesn't offer.
local function visible_extras()
  local family = current_family()
  local offered = family and families[family].options or {}
  return vim.tbl_filter(function(extra)
    return not vim.list_contains(offered, extra.name)
  end, extras)
end

--- `name`'s style, links followed. One the theme leaves undefined is drawn as
--- the shallower highlight Neovim falls back to (`@string.documentation` as
--- `@string`), so take that one's.
local function style_of(name)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local parent = name:match("^(@.+)%.[^.]+$")
  if vim.tbl_isempty(hl) and parent then
    return style_of(parent)
  end
  return hl
end

--- Make every highlight an Extra italic that's on covers italic, keeping the
--- rest of its style. Run after every theme change (lua/theme.lua).
function M.apply_extras()
  local on = chosen_extras()
  local wanted = {}
  for _, extra in ipairs(visible_extras()) do
    wanted[extra] = on[extra.name] == true
  end
  -- Every extra's names, even those the theme leaves undefined.
  local names = vim.tbl_keys(vim.api.nvim_get_hl(0, {}))
  for _, extra in ipairs(extras) do
    vim.list_extend(names, extra.groups)
  end
  -- The rest of the extras' names as they look now: one that links or falls
  -- back to a name made italic (methods to functions, in some themes) would
  -- turn italic with it.
  local before = {}
  for _, name in ipairs(names) do
    local extra = owner(name)
    if extra and not wanted[extra] then
      before[name] = style_of(name)
    end
  end
  for _, name in ipairs(names) do
    local extra = owner(name)
    if extra and wanted[extra] then
      local hl = style_of(name)
      -- A `default` definition never replaces an existing one, so drop the flag.
      hl.italic, hl.default = true, nil
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
  -- Keep each of the rest as it was, if it turned italic.
  for name, hl in pairs(before) do
    if style_of(name).italic ~= hl.italic then
      hl.default = nil
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
  -- The family's own options, then the Extra italics, each labelled with its
  -- section: the family, or "extra".
  local rows = {}
  for _, option in ipairs(family and families[family].options or {}) do
    table.insert(rows, { option = option, section = family, label = option })
  end
  for _, extra in ipairs(visible_extras()) do
    table.insert(rows, { extra = extra.name, section = "extra", label = extra.label or extra.name })
  end
  local width = math.max(unpack(vim.tbl_map(function(row)
    return #row.section
  end, rows)))
  vim.ui.select(rows, {
    prompt = "Italics: " .. (family or "extra"),
    format_item = function(row)
      local is_on = row.extra and on[row.extra] or not row.extra and choice[row.option]
      local icon = is_on and icons.ui.Check or icons.ui.Close
      return ("%s  %-" .. width .. "s  %s"):format(icon, row.section, row.label)
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
