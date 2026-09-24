local h = require("harness")

local leader = vim.g.mapleader

local function breadcrumbs()
  return vim.api.nvim_eval_statusline(vim.wo.winbar, {
    winid = vim.api.nvim_get_current_win(),
    use_winbar = true,
  }).str
end

--- Move onto `M.greet`'s body as a user would, until the Breadcrumbs show it
--- (or `ms` has passed); return whether they do. The redraw is nudged outside
--- the wait's condition: firing autocmds inside it keeps vim.wait from timing out.
local function breadcrumbs_shown(ms)
  vim.api.nvim_win_set_cursor(0, { 4, 4 })
  for _ = 1, ms / 200 do
    vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
    if vim.wait(200, function()
      return breadcrumbs():find("greet", 1, true) ~= nil
    end, 20) then
      return true
    end
  end
  return false
end

--- Edit a Lua file with a couple of symbols, and wait until lua_ls has attached
--- and, unless they are hidden, Dropbar has drawn the Breadcrumbs.
local function open_lua()
  local file = vim.fn.tempname() .. ".lua"
  vim.fn.writefile(
    { "local M = {}", "", "function M.greet(name)", "  return 'hi ' .. name", "end", "", "return M" },
    file
  )
  vim.cmd.edit(file)
  h.eq(
    true,
    vim.wait(20000, function()
      return #vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" }) > 0
    end, 100),
    "lua_ls attached"
  )
  breadcrumbs_shown(10000)
end

--- The normal-mode mapping of `lhs` in the current buffer, else the global one.
local function mapping(lhs)
  return vim.fn.maparg(leader .. lhs, "n", false, true)
end

--- Floating windows opened by pressing `keys`, once one has appeared.
local function filetypes_opened_by(keys)
  local before = vim.api.nvim_list_wins()
  local function new()
    return vim
      .iter(vim.api.nvim_list_wins())
      :filter(function(win)
        return not vim.list_contains(before, win)
      end)
      :map(function(win)
        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      end)
      :totable()
  end
  vim.api.nvim_feedkeys(vim.keycode(keys), "mx", false)
  vim.wait(5000, function()
    return #new() > 0
  end, 50)
  return new()
end

--- Close every window but the current, non-floating one.
local function close_others()
  vim.cmd.stopinsert()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= vim.api.nvim_get_current_win() then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

h.test("<leader>kr renames in lspsaga's rename window", function()
  open_lua()
  local opened = filetypes_opened_by(leader .. "kr")
  close_others()
  h.eq(true, vim.list_contains(opened, "sagarename"), "windows opened: " .. vim.inspect(opened))
end)

h.test("<leader>ko opens lspsaga's outline", function()
  open_lua()
  local opened = filetypes_opened_by(leader .. "ko")
  close_others()
  h.eq(true, vim.list_contains(opened, "sagaoutline"), "windows opened: " .. vim.inspect(opened))
end)

h.test("<leader>cr, <leader>cs and <leader>cS stay the configured rename and symbol views", function()
  open_lua()
  -- LazyVim adds the LSP keys (<leader>cr) once the client has attached.
  vim.wait(5000, function()
    return mapping("cr").buffer == 1
  end, 50)
  h.eq(
    { cr = "Rename (inc-rename.nvim)", cs = "Aerial (Symbols)", cS = "LSP references/definitions/... (Trouble)" },
    { cr = mapping("cr").desc, cs = mapping("cs").desc, cS = mapping("cS").desc }
  )
end)

h.test("<leader>k is the navigation group in which-key", function()
  local groups = vim
    .iter(require("which-key.config").mappings)
    :filter(function(m)
      return m.group and vim.keycode(m.lhs) == leader .. "k"
    end)
    :map(function(m)
      return m.desc
    end)
    :totable()
  h.eq({ "navigation" }, groups, "which-key groups on <leader>k")
end)

h.test("<leader>kb hides the Breadcrumbs and shows them again", function()
  open_lua()
  h.eq(true, breadcrumbs():find("greet", 1, true) ~= nil, "Breadcrumbs shown after boot: " .. breadcrumbs())

  vim.api.nvim_feedkeys(leader .. "kb", "mx", false)
  -- Moving and editing make Dropbar redraw, and must not bring them back.
  vim.api.nvim_win_set_cursor(0, { 3, 10 })
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
  vim.wait(1000, function()
    return false
  end)
  h.eq("", vim.wo.winbar, "Breadcrumbs after the first <leader>kb")

  vim.api.nvim_feedkeys(leader .. "kb", "mx", false)
  h.eq(true, breadcrumbs_shown(3000), "Breadcrumbs after the second <leader>kb: " .. vim.wo.winbar)
end)

h.test("a file opened while the Breadcrumbs are hidden shows them once they're toggled back", function()
  open_lua()
  vim.api.nvim_feedkeys(leader .. "kb", "mx", false)
  open_lua()
  h.eq("", vim.wo.winbar, "Breadcrumbs while hidden")
  vim.api.nvim_feedkeys(leader .. "kb", "mx", false)
  h.eq(true, breadcrumbs_shown(3000), "Breadcrumbs after <leader>kb: " .. vim.wo.winbar)
end)

h.test("Lspsaga keeps rename and outline but disables its Breadcrumbs", function()
  open_lua()
  local config = require("lspsaga").config
  h.eq({ symbol_in_winbar = false, lightbulb = false, beacon = false, implement = false }, {
    symbol_in_winbar = config.symbol_in_winbar.enable,
    lightbulb = config.lightbulb.enable,
    beacon = config.beacon.enable,
    implement = config.implement.enable,
  })
end)

h.test("the disabled features register no lightbulb autocmds", function()
  open_lua()
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "SagaLightBulb" })
  h.eq({}, ok and autocmds or {}, "SagaLightBulb autocmds")
  local buf_ok = pcall(vim.api.nvim_get_autocmds, { group = "SagaLightBulb" .. vim.api.nvim_get_current_buf() })
  h.eq(false, buf_ok, "a per-buffer lightbulb augroup exists")
end)

h.test("the disabled features register no keys", function()
  open_lua()
  local saga = {}
  for _, mode in ipairs({ "n", "x", "o", "i" }) do
    for _, map in ipairs(vim.list_extend(vim.api.nvim_get_keymap(mode), vim.api.nvim_buf_get_keymap(0, mode))) do
      local text = ((map.rhs or "") .. " " .. (map.desc or "")):lower()
      if text:find("saga", 1, true) and not vim.list_contains({ "kr", "ko" }, map.lhs:sub(2)) then
        table.insert(saga, mode .. " " .. map.lhs .. " " .. text)
      end
    end
  end
  h.eq({}, saga, "lspsaga mappings besides rename and outline")
end)

-- Search keeps its background (see lua/theme.lua), and SagaSearch links to it.
local keeps = { "SagaSearch" }

for _, theme in ipairs(require("theme").themes) do
  h.test(theme .. ": Saga* groups have no background", function()
    require("lazy").load({ plugins = { "lspsaga.nvim" } })
    h.apply_theme(theme)
    -- lspsaga loads after the theme (on the first LSP attach) and only then
    -- defines its groups, some with a background: replay that.
    require("lspsaga.highlight").init_highlight()
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad", data = "lspsaga.nvim" })
    vim.wait(200, function()
      return false
    end)
    local solid = {}
    for name in pairs(vim.api.nvim_get_hl(0, {})) do
      local bg = vim.api.nvim_get_hl(0, { name = name, link = false }).bg
      if vim.startswith(name, "Saga") and bg and not vim.list_contains(keeps, name) then
        table.insert(solid, ("%s (#%06x)"):format(name, bg))
      end
    end
    table.sort(solid)
    h.eq({}, solid, "Saga groups with a background")
  end)
end

h.test("there are Curated themes to check Saga* groups against", function()
  h.eq(true, #require("theme").themes > 0, "require('theme').themes")
end)
