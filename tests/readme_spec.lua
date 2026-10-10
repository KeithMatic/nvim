-- The README's keymap tables are the cheat sheet (<leader>sK), so every key
-- this config defines with a description has to be in them. A key counts as
-- there when the README has it as a code span, in any table or paragraph.
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

--- The README's code spans, outside fenced blocks, as a set of canonical keys.
---@return table<string, true>
local function readme_keys()
  local text = table.concat(vim.fn.readfile(config .. "/README.md"), "\n"):gsub("```.-```", "")
  local keys = {}
  for span in text:gmatch("`([^`\n]+)`") do
    keys[canonical(span)] = true
  end
  return keys
end

--- Where this config defines keys, each as a function returning
--- { lhs, desc, where } entries. No one source sees every key.
---@type table<string, fun(): { [1]: string, [2]: string?, [3]: string }[]>
local sources = {
  -- The harness records vim.keymap.set calls from this config's files: a
  -- mapping whose rhs is a string keeps no source of its own.
  keymap_set = function()
    return vim.tbl_map(function(map)
      return { map.lhs, map.desc, map.file }
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
          table.insert(found, { map.lhs, map.desc, source:sub(#config_lua + 1) })
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
        table.insert(found, { key.lhs, key.desc, name })
      end
    end
    return found
  end,
}

--- Every key with a description from `source`, as canonical key → where.
---@param source fun(): { [1]: string, [2]: string?, [3]: string }[]
---@return table<string, string>
local function described(source)
  local keys = {}
  for _, key in ipairs(source()) do
    local lhs, desc, where = key[1], key[2], key[3]
    if desc and desc ~= "" and desc ~= "which_key_ignore" then
      keys[canonical(lhs)] = ("%s, in %s"):format(desc, where)
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

h.test("every key this config defines is in the README", function()
  local documented = readme_keys()
  local missing = {}
  for _, source in pairs(sources) do
    for key, where in pairs(described(source)) do
      if not documented[key] and not vim.list_contains(missing, key .. ": " .. where) then
        table.insert(missing, key .. ": " .. where)
      end
    end
  end
  table.sort(missing)
  h.eq({}, missing, "keys missing from README.md")
end)
