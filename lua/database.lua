-- The database a SQL buffer's queries run on, shown as the first of its
-- Breadcrumbs and clicked (or picked with dropbar's pick) to switch it. A
-- switch ties the buffer to that database, as :Sqmeow bind does, so every
-- statement after it runs there until the next switch.
local M = {}

-- The filetypes the lang.sql extra serves.
M.sql_ft = { "sql", "mysql", "plsql" }

--- The name a database goes by: a cluster's database by its own name, anything
--- else by the connection's.
local function db_name(connection)
  return connection.database or connection.current_database or connection.name
end

--- The server a connection is on, for telling same-named databases apart.
local function server_name(connection)
  local parent = connection.parent and require("sqmeow.state").connections[connection.parent]
  return parent and parent.name or connection.name
end

--- What the crumb for `buf` reads, and its highlight.
---@return string name
---@return string|nil hl Nil once it is connected.
function M.label(buf)
  local connection = require("sqmeow.api").target(buf)
  if not connection then
    return "no database", "DiagnosticWarn"
  end
  if connection.state ~= "connected" then
    return db_name(connection) .. "…", "Comment"
  end
  return db_name(connection), nil
end

--- Ask which open database `buf` runs its queries on.
function M.pick(buf)
  local state = require("sqmeow.state")
  local current = require("sqmeow.api").target(buf)

  local items = {}
  -- Once tied to one database, the buffer can go back to following the drawer's.
  if vim.b[buf].sqmeow_connection then
    local active = state.current_connection()
    table.insert(items, { follow = true, text = "Follow the drawer (" .. (active and db_name(active) or "none") .. ")" })
  end
  for _, connection in ipairs(state.connection_list()) do
    if connection.state == "connected" then
      local mark = current and current.id == connection.id and "● " or "  "
      table.insert(items, {
        connection = connection,
        text = ("%s%s  (%s)"):format(mark, db_name(connection), server_name(connection)),
      })
    end
  end

  if #items == 0 then
    return vim.notify("No database is open: open one in the Database drawer (<leader>Dd)", vim.log.levels.WARN)
  end

  vim.ui.select(items, {
    prompt = "Run queries on",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if not choice or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.b[buf].sqmeow_connection = choice.connection and choice.connection.name or nil
    M.refresh()
  end)
end

--- Redraw every crumb, after the database under one may have changed.
function M.refresh()
  if package.loaded["dropbar"] then
    require("dropbar.utils.bar").exec("update")
  end
end

--- A dropbar source with the one crumb: the database.
M.source = {
  get_symbols = function(buf)
    local name, hl = M.label(buf)
    return {
      require("dropbar.bar").dropbar_symbol_t:new({
        icon = require("util.icons").misc.Database,
        icon_hl = hl or "DropBarIconKindFile",
        name = name,
        name_hl = hl,
        on_click = function()
          M.pick(buf)
        end,
      }),
    }
  end,
}

--- Dropbar's `sources`, with the database crumb first in SQL buffers.
---@param default fun(buf: integer, win: integer): table[]
function M.sources(default)
  return function(buf, win)
    local sources = default(buf, win)
    if vim.list_contains(M.sql_ft, vim.bo[buf].filetype) then
      table.insert(sources, 1, M.source)
    end
    return sources
  end
end

return M
