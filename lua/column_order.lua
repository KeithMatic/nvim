-- The Column order of the Buffer sticks: Pinned files first, then the rest,
-- newly opened files at the end. buffer-sticks.nvim draws buffers in the order
-- they were created and can't sort them, so this wraps its buffer list
-- (docs/adr/0001-own-the-buffer-order.md). Previous/next file, moving a file,
-- pinning, the bulk closes and the Buffer list's split and close actions live
-- here too, since they all walk the same order. The order and pins are kept by
-- path in a session global.
local M = {}

local order = {} ---@type integer[] buffer numbers, pinned ones first
local pinned = {} ---@type table<integer, true>

--- The Buffer sticks' files, in Column order.
---@return {id: integer}[]
local function files()
  return require("buffer-sticks.buffers").get_buffer_list()
end

---@param list {id: integer}[]|integer[]
---@param buf integer
local function index_of(list, buf)
  for i, item in ipairs(list) do
    if (type(item) == "table" and item.id or item) == buf then
      return i
    end
  end
end

local function pinned_count()
  local n = 0
  for _, buf in ipairs(order) do
    n = n + (pinned[buf] and 1 or 0)
  end
  return n
end

local function redraw()
  if BufferSticks and BufferSticks.is_visible() then
    BufferSticks.show()
  end
end

--- Sort the plugin's buffers into Column order, adding new ones at the end.
---@param buffers {id: integer}[]
local function sort(buffers)
  order = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
  end, order)
  for _, b in ipairs(buffers) do
    if not index_of(order, b.id) then
      table.insert(order, b.id)
    end
  end
  local rank = {}
  for i, buf in ipairs(order) do
    rank[buf] = i
  end
  table.sort(buffers, function(a, b)
    return rank[a.id] < rank[b.id]
  end)
  return buffers
end

--- Previous/next file in Column order, wrapping round like :bnext.
---@param step integer
function M.cycle(step)
  local list = files()
  if #list == 0 then
    return
  end
  local i = index_of(list, vim.api.nvim_get_current_buf()) or (step > 0 and 0 or #list + 1)
  local target = list[(i - 1 + step * vim.v.count1) % #list + 1]
  vim.api.nvim_set_current_buf(target.id)
end

--- Move the current file up (-1) or down (1) the column, staying among its own
--- kind: a Pinned file can't move below an unpinned one, nor the other way.
---@param step integer
function M.move(step)
  local list = files()
  local cur = vim.api.nvim_get_current_buf()
  local i = index_of(list, cur)
  local neighbour = i and list[i + step]
  if not neighbour or not pinned[cur] ~= not pinned[neighbour.id] then
    return
  end
  local a, b = index_of(order, cur), index_of(order, neighbour.id)
  order[a], order[b] = order[b], order[a]
  redraw()
end

--- Pin the current file to the end of the Pinned files, or unpin it to the
--- head of the rest.
function M.toggle_pin()
  local cur = vim.api.nvim_get_current_buf()
  local i = index_of(order, cur)
  if not i then
    return
  end
  table.remove(order, i)
  local was_pinned = pinned[cur]
  pinned[cur] = not was_pinned or nil
  table.insert(order, pinned_count() + 1, cur)
  vim.notify(was_pinned and "Unpinned" or "Pinned", vim.log.levels.INFO, { title = "Buffer sticks" })
  redraw()
end

--- Close files in bulk, never the current one or a Pinned one.
---@param which "others"|"left"|"right"|"unpinned"
function M.close(which)
  local list = files()
  local cur = vim.api.nvim_get_current_buf()
  local here = index_of(list, cur)
  if not here and (which == "left" or which == "right") then
    return
  end
  for i, b in ipairs(list) do
    local side = which == "left" and i < here
      or which == "right" and i > here
      or which == "others"
      or which == "unpinned"
    if side and b.id ~= cur and not pinned[b.id] then
      Snacks.bufdelete(b.id)
    end
  end
end

--- Open the Buffer list, and put the chosen file where `how` says. The list's
--- preview has already swapped it into this window, so the file you started
--- in goes back first.
---@param how "vsplit"|"split"|"close"
function M.pick(how)
  local origin = vim.api.nvim_get_current_buf()
  BufferSticks.list({
    action = function(buffer, leave)
      leave()
      if vim.api.nvim_buf_is_valid(origin) and origin ~= buffer.id then
        vim.cmd("keepalt buffer " .. origin)
      end
      if how == "close" then
        Snacks.bufdelete(buffer.id)
      else
        vim.cmd(how)
        vim.api.nvim_set_current_buf(buffer.id)
      end
    end,
  })
end

--- Keep the order and pins, by path, where the session saves globals.
local function save()
  local paths, pins = {}, {}
  for _, buf in ipairs(order) do
    local name = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) or ""
    if name ~= "" then
      table.insert(paths, name)
      if pinned[buf] then
        table.insert(pins, name)
      end
    end
  end
  vim.g.BufferSticksOrder = vim.json.encode({ order = paths, pinned = pins })
end

local function restore()
  local ok, saved = pcall(vim.json.decode, vim.g.BufferSticksOrder or "")
  if not ok or type(saved) ~= "table" then
    return
  end
  local by_name = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    by_name[vim.api.nvim_buf_get_name(buf)] = buf
  end
  order, pinned = {}, {}
  for _, name in ipairs(saved.order or {}) do
    if by_name[name] then
      table.insert(order, by_name[name])
    end
  end
  for _, name in ipairs(saved.pinned or {}) do
    if by_name[name] then
      pinned[by_name[name]] = true
    end
  end
  redraw()
end

function M.setup()
  local buffers = require("buffer-sticks.buffers")
  local get_buffer_list = buffers.get_buffer_list
  buffers.get_buffer_list = function()
    return sort(get_buffer_list())
  end

  local group = vim.api.nvim_create_augroup("column_order", { clear = true })
  -- Closing a file by choice drops its pin; reopened, it goes to the end.
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(ev)
      pinned[ev.buf] = nil
      local i = index_of(order, ev.buf)
      if i then
        table.remove(order, i)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "PersistenceSavePre", callback = save })
  vim.api.nvim_create_autocmd("SessionLoadPost", { group = group, callback = restore })
end

return M
