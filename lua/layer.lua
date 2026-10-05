-- Layers: a named set of keys laid over the usual ones until you leave it, when
-- layers.nvim puts back exactly what was there. This applies what every layer
-- shares, so a layer (lua/layer/*.lua) is only its keys and hooks:
-- <esc> and q leave it, ? shows or hides its help, the statusline's mode icon
-- becomes its icon, and switching to another file leaves it (unless it's
-- global). One layer is active at a time.
-- Named `layer`, not `layers`: that's layers.nvim's own module.
local M = {}

---@class layer.Spec
---@field name string shown in the help window's title
---@field icon string from the Icon set
---@field colour string highlight group whose foreground colours the icon
---@field keys table<string, table[]> layers.nvim keymaps by mode: { lhs, rhs, { desc = ... } }
---@field scope? "buffer"|"global" "buffer" (the default): switching files leaves it
---@field enter? fun(): boolean? before the keys are laid; false refuses to enter
---@field leave? fun() after the keys are given back

---@class layer.Layer
---@field name string
---@field icon string
---@field colour string
---@field private spec layer.Spec
---@field private mode table layers.nvim's mode
---@field private buf? integer the buffer a "buffer" layer belongs to
local Layer = {}
Layer.__index = Layer

---@type layer.Layer?
local active

local group = vim.api.nvim_create_augroup("layer", { clear = true })

--- The help window's title: the icon in the layer's colour, then its name.
---@param self layer.Layer
local function title(self)
  return { { " " .. vim.trim(self.icon) .. " ", self.colour }, { self.name .. " ", "FloatTitle" } }
end

--- Whether `mode`'s help window is open. layers.nvim only forgets its window
--- when it closes it itself, so one closed another way (<C-w>o) is forgotten
--- here, or dismissing it would fail. Relies on its internal `_win` (the
--- plugin is pinned in lazy-lock.json; tests/layer_spec.lua covers it).
local function help_shown(mode)
  if mode._win and not vim.api.nvim_win_is_valid(mode._win) then
    mode._win = nil
  end
  return mode._win ~= nil
end

---@param spec layer.Spec
---@return layer.Layer
function M.new(spec)
  local self = setmetatable({ name = spec.name, icon = spec.icon, colour = spec.colour, spec = spec }, Layer)
  self.mode = require("layers").mode.new()
  local function leave()
    self:exit()
  end
  local keys = vim.deepcopy(spec.keys)
  keys.n = keys.n or {}
  vim.list_extend(keys.n, {
    {
      "?",
      function()
        self:toggle_help()
      end,
      { desc = "help" },
    },
    { "q", leave, { desc = "leave" } },
    { "<esc>", leave, { desc = "leave" } },
  })
  self.mode:keymaps(keys)
  return self
end

--- Lay the layer's keys, leaving any other layer first. Does nothing when its
--- `enter` refuses.
function Layer:enter()
  if active == self then
    return
  end
  if active then
    active:exit()
  end
  if self.spec.enter and self.spec.enter() == false then
    return
  end
  self.mode:activate()
  active = self
  if (self.spec.scope or "buffer") == "buffer" then
    self.buf = vim.api.nvim_get_current_buf()
    -- Only another file counts: not a float (a picker, blame, hover), a panel,
    -- or a diff's split (gitsigns' diffthis passes through it on the way back).
    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      callback = function(ev)
        if ev.buf ~= self.buf and vim.bo[ev.buf].buftype == "" and vim.api.nvim_win_get_config(0).relative == "" then
          self:exit()
        end
      end,
    })
  end
  vim.cmd.redrawstatus()
end

--- Give back the keys the layer covered and close its help.
function Layer:exit()
  if active ~= self then
    return
  end
  active = nil
  vim.api.nvim_clear_autocmds({ group = group })
  self.mode:deactivate()
  if help_shown(self.mode) then
    self.mode:dismiss_help()
  end
  if self.spec.leave then
    self.spec.leave()
  end
  vim.cmd.redrawstatus()
end

function Layer:toggle_help()
  if help_shown(self.mode) then
    self.mode:dismiss_help()
  else
    -- One list for every mode's keys, without "n:"/"x:" headers.
    self.mode:show_help({ force_mode_headers = false }, { title = title(self) })
  end
end

--- The layer that's active, if any.
---@return layer.Layer?
function M.active()
  return active
end

return M
