-- The statusline: LazyVim's lualine sections, with what I liked from my old
-- statusline added. Left: the mode icon, file size, diagnostics and diff (then
-- the filename, when toggled on). Right: the Python venv, plugin updates, git
-- branch, position and a scrollbar. Colours all come from the theme: section
-- colours from its lualine theme (lua/theme.lua), the rest from highlights.
-- Blank while the Explorer is focused.
local M = {}

local icons = require("util.icons")
local theme = require("theme")

-- By the first letter of mode(): the icon, and its Mode colour. Anything
-- else (normal, hit-enter) has the normal icon in the section's colour.
local visual = { icons.modes.visual, "visual" }
local terminal = { icons.modes.terminal, "insert" }
local modes = {
  i = { icons.modes.insert, "insert" },
  v = visual,
  V = visual,
  ["\22"] = visual, -- blockwise
  s = visual,
  S = visual,
  ["\19"] = visual,
  R = { icons.modes.replace, "delete" },
  t = terminal,
  ["!"] = terminal,
  c = { icons.misc.Vim },
}
-- The Mode colour while an operator waits for its motion.
local operator_colours = { y = "copy", d = "delete", c = "delete" }

--- The mode icon, and the Mode colour it's drawn in (none: the section's own
--- colour), for the current mode.
---@return string icon, string? mode_colour
local function mode()
  local m = vim.fn.mode(1)
  if vim.startswith(m, "no") then -- waiting for a motion: d, c or y
    return icons.modes.normal, operator_colours[vim.v.operator]
  end
  local found = modes[m:sub(1, 1)] or {}
  return found[1] or icons.modes.normal, found[2]
end

local mode_icon = {
  function()
    return vim.trim((mode()))
  end,
  color = function()
    local _, colour = mode()
    return colour and { fg = theme.mode_color(colour) } or nil
  end,
}

local python_venv = {
  function()
    return vim.fs.basename(vim.env.VIRTUAL_ENV)
  end,
  cond = function()
    return vim.bo.filetype == "python" and vim.env.VIRTUAL_ENV ~= nil
  end,
  -- Python's glyph in its own colour, as the filetype icons are drawn.
  icon = (function()
    local glyph, hl = require("mini.icons").get("filetype", "python")
    return { glyph, color = hl }
  end)(),
}

--- How far through the file the cursor is, as a block that empties towards the end.
local scrollbar = {
  function()
    local blocks = { "█", "▇", "▆", "▅", "▄", "▃", "▂", " " }
    local ratio = vim.fn.line(".") / vim.fn.line("$")
    return blocks[math.max(1, math.ceil(ratio * #blocks))]
  end,
}

--- The index in `section` of the component `name` (a component's first item:
--- its name, or its function).
local function index_of(section, name)
  for i, component in ipairs(section) do
    if (type(component) == "table" and component[1] or component) == name then
      return i
    end
  end
end

--- Add my components to LazyVim's lualine `opts`, in place.
---@param opts table
function M.extend(opts)
  local s = opts.sections

  s.lualine_a = { mode_icon }

  -- The branch moves right, next to the position; the file size takes its place.
  local branch = table.remove(s.lualine_b, index_of(s.lualine_b, "branch"))
  s.lualine_b = { "filesize" }
  if type(branch) == "string" then
    branch = { branch }
  end
  branch.icon = icons.git.Branch

  -- The filetype icon and path, off unless toggled on (<leader>uN).
  local filetype = index_of(s.lualine_c, "filetype")
  for i = filetype, filetype + 1 do -- LazyVim's path follows the icon
    s.lualine_c[i].cond = function()
      return theme.statusline_filename
    end
  end

  -- LazyVim's diff, drawn by lualine-so-fancy, moves left after diagnostics.
  local diff = table.remove(s.lualine_x, index_of(s.lualine_x, "diff"))
  diff[1] = "fancy_diff"
  table.insert(s.lualine_c, index_of(s.lualine_c, "diagnostics") + 1, diff)

  local updates = require("lazy.status").updates
  table.insert(s.lualine_x, index_of(s.lualine_x, updates), python_venv)

  table.insert(s.lualine_y, 1, branch)
  table.insert(s.lualine_y, scrollbar)

  -- Blank while the Explorer is focused. Remove this for LazyVim's default
  -- (its neo-tree extension shows the Explorer's folder).
  table.insert(opts.options.disabled_filetypes.statusline, "neo-tree")
end

--- The <leader>uN toggle: show or hide the filename, remembered across restarts.
function M.filename_toggle()
  return Snacks.toggle({
    name = "Statusline Filename",
    get = function()
      return theme.statusline_filename
    end,
    set = function(shown)
      theme.set_statusline_filename(shown)
      if package.loaded.lualine then
        require("lualine").refresh()
      end
    end,
  })
end

return M
