-- The Terminal manager: nvzone/floaterm's float of named terminals beside the
-- Terminal list, bent to fit this config. Its three windows look like every
-- other float (rounded, NormalFloat and FloatBorder), and q/<Esc> only ever
-- Hide it: volt's own q/<Esc> forget every terminal, orphaning the shells.
-- Some of this reaches into floaterm.state and floaterm.utils, which aren't
-- documented API. See docs/floaterm-design.md.
local M = {}

--- Show the Terminal manager, or Hide it with every terminal still running.
--- (floaterm's own, behind a name that loads it on first use.)
function M.toggle()
  require("floaterm").toggle()
end

--- Whether the Terminal manager is shown; false before floaterm has loaded.
---@return boolean
function M.shown()
  return package.loaded["floaterm.state"] ~= nil and require("floaterm.state").volt_set == true
end

--- Add a terminal started in `dir`, named after it, showing the Terminal
--- manager first if it's hidden.
---@param dir string
function M.new_at(dir)
  if not M.shown() then
    require("floaterm").open()
  end
  -- floaterm runs `shell -c '<cmd>; shell'`, leaving an interactive shell in `dir`.
  require("floaterm.api").new_term({ name = vim.fs.basename(dir), cmd = "cd " .. vim.fn.shellescape(dir) })
end

--- q and <Esc> in normal mode Hide the Terminal manager in `buf`.
---@param buf integer
local function hide_keys(buf)
  for _, lhs in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", lhs, M.toggle, { buffer = buf, desc = "Hide Terminal Manager" })
  end
end

-- A first <Esc> goes to the shell; a second within 200 ms leaves terminal
-- mode instead (Snacks terminals' double escape).
local last_esc = 0 -- vim.uv.hrtime() of an <Esc> that went to the shell
local function double_esc()
  local now = vim.uv.hrtime()
  if now - last_esc < 200 * 1e6 then
    last_esc = 0
    return "<C-\\><C-n>"
  end
  last_esc = now
  return "<Esc>"
end

-- What floaterm is given (lua/plugins/terminal.lua).
M.opts = {
  border = true, -- the borderless look paints volt's colours, black under Transparency
  size = { w = 85, h = 80 },
  -- One shell to start with, named after the project folder.
  terminals = function()
    return { { name = vim.fs.basename(vim.fn.getcwd()) } }
  end,
  mappings = {
    -- Runs each time a terminal is first shown, right after volt has mapped
    -- its discarding q/<Esc> again on that terminal, the Terminal list and
    -- floaterm's one-line header above the terminal, so all three are put back.
    term = function(buf)
      local state = require("floaterm.state")
      for _, each in ipairs({ buf, state.sidebuf, state.barbuf }) do
        hide_keys(each)
      end
      vim.keymap.set("t", "<Esc>", double_esc, { buffer = buf, expr = true, desc = "Double Escape to Normal Mode" })
    end,
  },
}

-- A float's colours: each group a floaterm window draws with, and the float
-- group it takes its colours from.
M.float_colors = { Normal = "NormalFloat", FloatBorder = "FloatBorder" }

local float_winhl = vim
  .iter(vim.spairs(M.float_colors))
  :map(function(group, float)
    return group .. ":" .. float
  end)
  :join(",")

--- Give a floaterm window a float's rounded border and colours: through
--- 'winhighlight', or through `ns` for a window drawn with that highlight
--- namespace, which wins over 'winhighlight'.
---@param win? integer
---@param ns? integer
local function as_float(win, ns)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  vim.api.nvim_win_set_config(win, { border = "rounded" })
  if not ns then
    vim.wo[win].winhighlight = float_winhl
    return
  end
  for group, float in pairs(M.float_colors) do
    vim.api.nvim_set_hl(ns, group, vim.api.nvim_get_hl(0, { name = float, link = false }))
  end
end

--- Set floaterm up with `opts`, and restyle its windows whenever it draws them.
---@param opts table
function M.setup(opts)
  local floaterm, utils, state = require("floaterm"), require("floaterm.utils"), require("floaterm.state")
  floaterm.setup(opts)

  -- The terminal window, on open and whenever floaterm makes it again.
  local set_termwin_hl = utils.set_termwin_hl
  utils.set_termwin_hl = function()
    set_termwin_hl()
    as_float(state.win)
  end

  local open = floaterm.open
  floaterm.open = function()
    open()
    as_float(state.barwin)
    as_float(state.sidewin, state.ns) -- the Terminal list
  end
end

return M
