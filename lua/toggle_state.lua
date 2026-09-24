-- Persistent toggle choices. State is separate from theme.json so editor
-- behaviour can be reset without losing the Curated theme or Tint.
--
-- Recovery: if a saved toggle causes trouble, run :ToggleStateReset (or delete
-- stdpath("state")/toggle-state.json, ~/.local/state/nvim/toggle-state.json by
-- default); every registered toggle returns to its default after restart.
local M = {}

local state_file = vim.fn.stdpath("state") .. "/toggle-state.json"
local state

local function empty()
  return { version = 1, toggles = {} }
end

local function valid(decoded)
  return type(decoded) == "table" and decoded.version == 1 and type(decoded.toggles) == "table" and decoded.toggles
    or nil
end

local function read()
  if state then
    return state
  end
  local ok, decoded = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state_file), "\n"))
  end)
  state = ok and valid(decoded) and decoded or empty()
  return state
end

local function write()
  vim.fn.mkdir(vim.fs.dirname(state_file), "p")
  local temporary = ("%s.%d.tmp"):format(state_file, vim.fn.getpid())
  local ok, err = pcall(vim.fn.writefile, { vim.json.encode(read()) }, temporary)
  if not ok then
    error(err)
  end
  local renamed, rename_err = vim.uv.fs_rename(temporary, state_file)
  if not renamed then
    vim.fn.delete(temporary)
    error(rename_err)
  end
end

--- Forget the cached file, so the next read sees the current contents.
function M.reload()
  state = nil
end

--- Read a saved value when its type matches the default.
---@generic T
---@param key string
---@param default T
---@return T
function M.get(key, default)
  local value = read().toggles[key]
  if type(value) == type(default) then
    return value
  end
  return default
end

function M.has(key)
  return read().toggles[key] ~= nil
end

--- Save a toggle value, preserving values registered by lazy-loaded plugins.
---@param key string
---@param value boolean|string|number
function M.set(key, value)
  read().toggles[key] = value
  write()
end

--- Wrap a setter so state changes only after the underlying operation succeeds.
---@param key string
---@param apply fun(value: any)
---@return fun(value: any)
function M.setter(key, apply)
  return function(value)
    apply(value)
    M.set(key, value)
  end
end

--- Persist a Snacks toggle and optionally restore its saved state now.
---@param key string
---@param toggle snacks.toggle.Class
---@param opts? {default?: boolean, restore?: boolean}
---@return snacks.toggle.Class
function M.persist(key, toggle, opts)
  opts = opts or {}
  local default = opts.default
  if default == nil then
    default = toggle:get()
  end
  local apply = toggle.opts.set
  toggle.opts.set = M.setter(key, apply)
  if opts.restore ~= false then
    apply(M.get(key, default))
  end
  return toggle
end

function M.reset()
  state = empty()
  vim.fn.delete(state_file)
end

vim.api.nvim_create_user_command("ToggleStateReset", function()
  M.reset()
  vim.notify("Saved toggle state cleared; defaults return after restart", vim.log.levels.INFO, {
    title = "Toggle state",
  })
end, { desc = "Restore toggle defaults after restart" })

return M
