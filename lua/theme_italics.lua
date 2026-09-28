-- Theme italics: which syntax each theme family draws in italics, chosen per
-- family from a picker (<leader>uy) that re-applies the theme on each change.
-- Saved in theme.json beside the theme and tint (lua/theme.lua). The line
-- diagnostics and Breadcrumbs are italic whatever the theme, so they're not here.
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

--- Set up `family` again with its chosen italics, and re-apply the theme.
local function reload(family)
  local opts = LazyVim.opts(families[family].plugin)
  opts.styles = vim.tbl_extend("force", opts.styles or {}, M.styles(family))
  require(family).setup(opts)
  vim.cmd.colorscheme(vim.g.colors_name)
end

--- Pick an option to flip; the list reopens after each, until closed.
function M.pick()
  local family = current_family()
  if not family then
    Snacks.notify.warn("No italic options for " .. (vim.g.colors_name or "this theme"), { title = "Theme italics" })
    return
  end
  local choice = chosen(family)
  vim.ui.select(families[family].options, {
    prompt = "Italics: " .. family,
    format_item = function(option)
      return (choice[option] and icons.ui.Check or icons.ui.Close) .. "  " .. option
    end,
  }, function(option)
    if not option then
      return
    end
    choice[option] = not choice[option]
    local italics = require("theme").saved().italics or {}
    italics[family] = choice
    require("theme").save({ italics = italics })
    reload(family)
    vim.schedule(M.pick)
  end)
end

return M
