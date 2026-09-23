-- The statusline: LazyVim's lualine sections, with what I liked from my old
-- statusline added. Left: the mode icon, file size, diagnostics and diff.
-- Centre: the filename (<leader>uN hides it). Right: the Python venv, plugin
-- updates, the filetype (coloured by its language server's state), git
-- branch, position, a scrollbar and the clock.
-- Colours all come from the theme. Only the mode icon and the filename follow
-- the mode; every other item has an icon in its own colour, and text in the
-- theme's soft foreground (lua/theme.lua's lualine theme).
-- Blank while the Explorer is focused.
local M = {}

local icons = require("util.icons")
local theme = require("theme")

-- By the first letter of mode(): the icon, and its Mode colour. Anything
-- else (normal, hit-enter) has the normal icon in the mode section's colour.
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

--- The mode icon, and the Mode colour it's drawn in (none: the mode
--- section's own colour), for the current mode.
---@return string icon, string? mode_colour
local function mode()
  local m = vim.fn.mode(1)
  if vim.startswith(m, "no") then -- waiting for a motion: d, c or y
    return icons.modes.normal, operator_colours[vim.v.operator]
  end
  local found = modes[m:sub(1, 1)] or {}
  return found[1] or icons.modes.normal, found[2]
end

--- The current mode's colour: the mode icon's and the filename's.
local function mode_colour()
  local _, colour = mode()
  if colour then
    return { fg = theme.mode_color(colour) }
  end
  return { fg = Snacks.util.color("lualine_a" .. require("lualine.highlight").get_mode_suffix()) }
end

--- `group`'s foreground in the current theme, as a lualine colour.
local function fg(group)
  return { fg = Snacks.util.color(group) }
end

--- A lualine colour function for `group`'s foreground: looked up on each
--- redraw, so it follows theme changes.
local function fg_of(group)
  return function()
    return fg(group)
  end
end

--- An icon from the Icon set, drawn in `group`'s foreground.
local function icon(glyph, group)
  return { vim.trim(glyph), color = fg_of(group) }
end

local mode_icon = {
  function()
    return vim.trim((mode()))
  end,
  color = mode_colour,
}

local function show_filename()
  return theme.statusline_filename and vim.fn.expand("%:t") ~= ""
end

-- Name and extension only: the path is the Breadcrumbs' job.
local filename = {
  function()
    return vim.fn.expand("%:t")
  end,
  cond = show_filename,
  color = mode_colour,
  padding = { left = 0, right = 1 }, -- the filetype icon before it has its space
}

-- Filetypes a configured language server covers, as they're asked about.
local served = {}

--- Whether LazyVim is set to run a language server for `filetype`, installed
--- or not (Mason's servers are only enabled once installed). Only known once
--- LazyVim has set the servers up (on opening a file). By hand: neither
--- LazyVim nor lualine tells "should have a server" from "has none".
local function has_server(filetype)
  if served[filetype] == nil and LazyVim.is_loaded("nvim-lspconfig") then
    local servers = LazyVim.opts("nvim-lspconfig").servers or {}
    served[filetype] = vim.iter(servers):any(function(name, server)
      local wanted = name ~= "*" and server ~= false and not (type(server) == "table" and server.enabled == false)
      local config = wanted and vim.lsp.config[name]
      return config and vim.list_contains(config.filetypes or {}, filetype) or false
    end)
  end
  return served[filetype]
end

-- The filetype, in the theme's "ok" colour with a language server attached,
-- its error colour when one should be but isn't, and muted when none exists.
local filetype_status = {
  "filetype",
  colored = false, -- the icon too
  color = function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
      return fg("DiagnosticOk")
    end
    return fg(has_server(vim.bo.filetype) and "DiagnosticError" or "Comment")
  end,
}

local updates = {
  function()
    return tostring(#require("lazy.manage.checker").updated)
  end,
  cond = function()
    return require("lazy.status").has_updates()
  end,
  -- The Icon set's: lazy.nvim's own glyph doesn't render.
  icon = icon(icons.ui.Package, "Special"),
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

local blocks = { "█", "▇", "▆", "▅", "▄", "▃", "▂", "▁" }

--- Which of the scrollbar's blocks the cursor's line is in.
local function block()
  return math.max(1, math.ceil(vim.fn.line(".") / vim.fn.line("$") * #blocks))
end

--- How far through the file the cursor is, as a block that empties towards
--- the end, graded through the theme's function, statement and constant
--- colours (blue, purple, then orange in the Curated themes).
local scrollbar = {
  function()
    return blocks[block()]
  end,
  color = function()
    local stops = {}
    for _, group in ipairs({ "Function", "Statement", "Constant" }) do
      table.insert(stops, Snacks.util.color(group)) -- skipped when the theme has none
    end
    if #stops < 2 then
      return nil
    end
    local along = (block() - 1) / (#blocks - 1) * (#stops - 1) -- 0 to #stops - 1
    local from = math.min(math.floor(along) + 1, #stops - 1)
    return { fg = theme.blend(stops[from + 1], stops[from], along - (from - 1)) }
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
  s.lualine_b = { { "filesize", icon = icon(icons.ui.File, "Constant") } }
  if type(branch) == "string" then
    branch = { branch }
  end
  branch.icon = icon(icons.git.Branch, "Statement")

  -- LazyVim's filetype icon moves to the centre, before the filename, in place
  -- of its path.
  local at = index_of(s.lualine_c, "filetype")
  table.remove(s.lualine_c, at + 1) -- the path
  local filetype_icon = table.remove(s.lualine_c, at)
  filetype_icon.cond = show_filename

  -- LazyVim's diff, drawn by lualine-so-fancy, moves left after diagnostics.
  local diff = table.remove(s.lualine_x, index_of(s.lualine_x, "diff"))
  diff[1] = "fancy_diff"
  table.insert(s.lualine_c, index_of(s.lualine_c, "diagnostics") + 1, diff)

  -- "%=" splits the bar's free space evenly either side of the filename.
  vim.list_extend(s.lualine_c, { { "%=", padding = 0 }, filetype_icon, filename })

  local lazy_updates = index_of(s.lualine_x, require("lazy.status").updates)
  s.lualine_x[lazy_updates] = updates
  table.insert(s.lualine_x, lazy_updates, python_venv)
  table.insert(s.lualine_x, filetype_status)

  table.insert(s.lualine_y, 1, branch)
  s.lualine_y[index_of(s.lualine_y, "progress")].icon = icon(icons.misc.location_point, "Function")
  table.insert(s.lualine_y, scrollbar)

  -- LazyVim's clock, rebuilt to give its glyph a colour of its own.
  s.lualine_z = {
    {
      function()
        return os.date("%R")
      end,
      icon = icon(icons.ui.Clock, "Operator"),
    },
  }

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
