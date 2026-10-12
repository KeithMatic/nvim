-- The README's keymap tables are the cheat sheet (<leader>sK), so every key
-- this config defines with a description has to be in them: as a code span in
-- the first cell of a table row. A key that does different things in different
-- modes (<C-a>: select all, or the line's start in insert) needs a row naming
-- each mode.
local h = require("harness")

local config = vim.fn.stdpath("config")
local config_lua = config .. "/lua/"

--- `lhs` as Neovim reads it, so `<leader>x` and `<Space>x`, or `<S-h>` and `H`,
--- compare equal.
---@param lhs string
---@return string
local function canonical(lhs)
  return vim.fn.keytrans(vim.keycode(lhs))
end

--- The README's table rows that name keys, outside fenced blocks: the keys
--- in the row's first cell (canonical), and the row's text, lower-cased.
---@return { keys: table<string, true>, text: string }[]
local function readme_rows()
  local text = table.concat(vim.fn.readfile(config .. "/README.md"), "\n"):gsub("```.-```", "")
  local rows = {}
  for line in text:gmatch("[^\n]+") do
    local first = line:match("^|([^|]*)|")
    local keys = {}
    for span in (first or ""):gmatch("`([^`]+)`") do
      keys[canonical(span)] = true
    end
    if next(keys) then
      table.insert(rows, { keys = keys, text = line:lower() })
    end
  end
  return rows
end

-- How a row names each mode, in its Action or Where cell.
local mode_words = {
  n = { "normal" },
  i = { "insert" },
  x = { "visual" },
  v = { "visual" },
  s = { "select" },
  o = { "operator" },
  c = { "command line" },
  t = { "terminal", "anywhere" },
}

--- Whether a row of `rows` has `key` in its first cell and, when `mode` is
--- given, names it.
---@param rows { keys: table<string, true>, text: string }[]
---@param key string
---@param mode? string
local function in_a_row(rows, key, mode)
  return vim.iter(rows):any(function(row)
    return row.keys[key]
      and (
        not mode
        or vim.iter(mode_words[mode] or { mode }):any(function(word)
          return row.text:find(word, 1, true) ~= nil
        end)
      )
  end)
end

--- Where this config defines keys, each as a function returning
--- { lhs, desc, where, modes } entries. No one source sees every key.
---@type table<string, fun(): { [1]: string, [2]: string?, [3]: string, [4]: string[] }[]>
local sources = {
  -- The harness records vim.keymap.set calls from this config's files: a
  -- mapping whose rhs is a string keeps no source of its own.
  keymap_set = function()
    return vim.tbl_map(function(map)
      return { map.lhs, map.desc, map.file, map.modes }
    end, h.config_keymaps)
  end,
  -- Mappings whose callback is defined in this config, though set by a helper
  -- elsewhere (Snacks.toggle's map).
  callbacks = function()
    local found = {}
    for _, mode in ipairs({ "n", "x", "o", "i", "t", "c" }) do
      for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        local source = map.callback and debug.getinfo(map.callback, "S").source:gsub("^@", "") or ""
        if vim.startswith(source, config_lua) then
          table.insert(found, { map.lhs, map.desc, source:sub(#config_lua + 1), { mode } })
        end
      end
    end
    return found
  end,
  -- The keys of this config's own lazy.nvim specs: a spec of its plugin
  -- modules alone, without LazyVim's.
  lazy_specs = function()
    local found = {}
    local Plugin = require("lazy.core.plugin")
    local spec = Plugin.Spec.new({ import = "plugins" }, { optional = true })
    for name, plugin in pairs(spec.plugins) do
      for _, key in pairs(require("lazy.core.handler.keys").resolve(Plugin.values(plugin, "keys", true))) do
        local mode = key.mode or "n"
        table.insert(found, { key.lhs, key.desc, name, type(mode) == "table" and mode or { mode } })
      end
    end
    return found
  end,
}

--- Every key with a description from `source`, as canonical key → mode →
--- { desc, where }.
---@param source fun(): { [1]: string, [2]: string?, [3]: string, [4]: string[] }[]
---@return table<string, table<string, { desc: string, where: string }>>
local function described(source)
  local keys = {}
  for _, key in ipairs(source()) do
    local lhs, desc, where, modes = key[1], key[2], key[3], key[4]
    if desc and desc ~= "" and desc ~= "which_key_ignore" then
      local by_mode = keys[canonical(lhs)] or {}
      for _, mode in ipairs(modes) do
        by_mode[mode] = { desc = desc, where = where }
      end
      keys[canonical(lhs)] = by_mode
    end
  end
  return keys
end

-- A source finding nothing would make the README test pass for nothing.
for name, source in pairs(sources) do
  h.test(name .. " finds keys", function()
    h.eq(true, next(described(source)) ~= nil, name .. " found a key")
  end)
end

--- Every key with a description, from every source: canonical key → mode →
--- { desc, where }.
local function all_described()
  local keys = {}
  for _, source in pairs(sources) do
    for key, by_mode in pairs(described(source)) do
      keys[key] = vim.tbl_extend("force", keys[key] or {}, by_mode)
    end
  end
  return keys
end

h.test("every key this config defines is in a README table", function()
  local rows = readme_rows()
  local missing = {}
  for key, by_mode in pairs(all_described()) do
    if not in_a_row(rows, key) then
      local _, first = next(by_mode)
      assert(first, key .. " has no mode") -- described() only adds keys with one
      table.insert(missing, ("%s: %s, in %s"):format(key, first.desc, first.where))
    end
  end
  table.sort(missing)
  h.eq({}, missing, "keys missing from README.md's tables")
end)

h.test("a key that does different things in different modes has a row naming each mode", function()
  local rows = readme_rows()
  local missing = {}
  for key, by_mode in pairs(all_described()) do
    local descs = {}
    for _, map in pairs(by_mode) do
      descs[map.desc] = true
    end
    if vim.tbl_count(descs) > 1 then
      for mode, map in pairs(by_mode) do
        if not in_a_row(rows, key, mode) then
          table.insert(missing, ("%s in mode %s: %s, in %s"):format(key, mode, map.desc, map.where))
        end
      end
    end
  end
  table.sort(missing)
  h.eq({}, missing, "no README row names the mode")
end)
