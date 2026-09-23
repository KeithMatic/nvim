-- The statusline: LazyVim's lualine sections, with what I liked from my old
-- statusline added. Left: the mode icon, file size, diagnostics and diff.
-- Centre: the filename (<leader>uN hides it). Right: the Python venv, plugin
-- updates, the filetype (coloured by its language server's state), git
-- branch, position, a scrollbar and the clock.
-- Colours all come from the theme. Only the mode icon and the filename follow
-- the mode (the filename's icon keeps the file's colour); every other item,
-- icon and text, has a colour of its own.
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
    return icons.separators.honeycomb.right, operator_colours[vim.v.operator]
  end
  local found = modes[m:sub(1, 1)] or {}
  return found[1] or icons.separators.honeycomb.right, found[2]
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

--- Give `component` an icon from the Icon set, and draw both in `group`'s
--- foreground.
---@return table component
local function coloured(component, glyph, group)
  component.icon, component.color = vim.trim(glyph), fg_of(group)
  return component
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

-- Name and extension only (the path is the Breadcrumbs' job), bold italic.
local filename = {
  function()
    return vim.fn.expand("%:t")
  end,
  cond = show_filename,
  color = function()
    return vim.tbl_extend("force", mode_colour(), { gui = "bold,italic" })
  end,
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

-- The Icon set's package glyph: lazy.nvim's own doesn't render.
local updates = coloured({
  function()
    return tostring(#require("lazy.manage.checker").updated)
  end,
  cond = function()
    return require("lazy.status").has_updates()
  end,
}, icons.ui.Package, "Special")

local python_venv = {
  function()
    return vim.fs.basename(vim.env.VIRTUAL_ENV)
  end,
  cond = function()
    return vim.bo.filetype == "python" and vim.env.VIRTUAL_ENV ~= nil
  end,
  -- Python's glyph and colour, as the filetype icons are drawn.
  icon = require("mini.icons").get("filetype", "python"),
  color = fg_of(select(2, require("mini.icons").get("filetype", "python"))),
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
  s.lualine_b = { coloured({ "filesize" }, icons.ui.Code, "Constant") }
  if type(branch) == "string" then
    branch = { branch }
  end
  coloured(branch, icons.git.Branch, "Statement")

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

  -- "%=" splits the bar's free space evenly either side of the filename;
  -- M.centre() then pads the narrower side, so it's at the bar's middle.
  vim.list_extend(s.lualine_c, { { "%=", padding = 0 }, filetype_icon, filename })

  local lazy_updates = index_of(s.lualine_x, require("lazy.status").updates)
  s.lualine_x[lazy_updates] = updates
  table.insert(s.lualine_x, lazy_updates, python_venv)
  table.insert(s.lualine_x, filetype_status)

  table.insert(s.lualine_y, 1, branch)
  coloured(s.lualine_y[index_of(s.lualine_y, "progress")], icons.misc.location_point, "Function")
  s.lualine_y[index_of(s.lualine_y, "location")].color = fg_of("Function")
  table.insert(s.lualine_y, scrollbar)

  -- LazyVim's clock, rebuilt to give it a colour of its own.
  s.lualine_z = {
    coloured({
      function()
        return os.date("%R")
      end,
    }, icons.ui.Clock, "Operator"),
  }

  -- Blank while the Explorer is focused. Remove this for LazyVim's default
  -- (its neo-tree extension shows the Explorer's folder).
  table.insert(opts.options.disabled_filetypes.statusline, "neo-tree")
end

--- The display width of statusline `text` once drawn.
local function width(text)
  return vim.api.nvim_eval_statusline(text, { maxwidth = 10000 }).width
end

--- Put the centre of lualine's statusline `line` (between its two "%=") at
--- the middle of the bar, not of the space between the left and right items:
--- the narrower side gets spaces for the difference, as many as the bar has
--- room for.
---@param line string?
---@return string?
function M.centre(line)
  -- The two "%=" markers, skipping escaped "%%" (a "%" in a filename).
  local markers = {}
  local at = 1
  while #markers < 2 do
    local found = line and line:find("%%[%%=]", at)
    if not found then
      return line
    end
    if line:sub(found + 1, found + 1) == "=" then
      table.insert(markers, found)
    end
    at = found + 2
  end
  local left, middle, right =
    line:sub(1, markers[1] - 1), line:sub(markers[1] + 2, markers[2] - 1), line:sub(markers[2] + 2)
  local left_width, right_width = width(left), width(right)
  local bar = vim.o.laststatus == 3 and vim.o.columns or vim.api.nvim_win_get_width(0)
  local free = bar - left_width - width(middle) - right_width
  local pad = (" "):rep(math.max(0, math.min(math.abs(right_width - left_width), free)))
  if right_width > left_width then
    middle = pad .. middle
  else
    right = pad .. right
  end
  return left .. "%=" .. middle .. "%=" .. right
end

--- Have lualine's statusline centred by M.centre(): lualine draws the line
--- section by section, so no component knows the right side's width in time.
function M.centre_lualine()
  local lualine = require("lualine")
  local draw = lualine.statusline
  lualine.statusline = function(...)
    return M.centre(draw(...))
  end
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
