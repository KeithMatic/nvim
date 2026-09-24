-- Dropbar's persistent visibility. The plugin owns only winbars whose format
-- is its own expression; other plugins' winbars are never cleared.
local M = {}

local state = require("toggle_state")
local winbar = "%{%v:lua.dropbar()%}"
local toggle
local pending

function M.enabled()
  if pending ~= nil then
    return pending
  end
  return state.get("ui.dropbar", true)
end

---@param default_enable fun(buf: integer?, win: integer?, info: table?): boolean
function M.enable(default_enable)
  return function(buf, win, info)
    return M.enabled() and default_enable(buf, win, info)
  end
end

local function bars()
  local found = {}
  for _, by_window in pairs(require("dropbar.utils.bar").get()) do
    for _, bar in pairs(by_window) do
      table.insert(found, bar)
    end
  end
  return found
end

local function show()
  local utils = require("dropbar.utils.bar")
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    utils.attach(vim.api.nvim_win_get_buf(window), window, {})
  end
end

local function hide()
  require("dropbar.utils.menu").exec("close")
  for _, bar in ipairs(bars()) do
    if vim.api.nvim_win_is_valid(bar.win) and vim.wo[bar.win].winbar == winbar then
      vim.wo[bar.win].winbar = ""
    end
    bar:del()
  end
end

function M.set_enabled(enabled)
  pending = enabled
  local ok, err = pcall(enabled and show or hide)
  pending = nil
  if not ok then
    error(err)
  end
  state.set("ui.dropbar", enabled)
end

function M.toggle()
  if not toggle then
    toggle = Snacks.toggle({
      name = "Breadcrumbs",
      get = M.enabled,
      set = M.set_enabled,
    })
  end
  return toggle
end

return M
