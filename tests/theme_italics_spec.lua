local h = require("harness")

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- `group`'s definition, links followed.
local function hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

--- Whether `group` is italic, links followed.
local function italic(group)
  return hl(group).italic == true
end

--- The saved state file, decoded.
local function saved()
  return vim.json.decode(table.concat(vim.fn.readfile(state_file), "\n"))
end

--- Let the scheduled restyle (and the picker's scheduled reopen) run.
local function settle()
  vim.wait(300, function()
    return false
  end)
end

--- Open the Theme italics picker (<leader>uy), flip the row whose text ends
--- with `label` (nil: flip nothing), and close it when it reopens. Returns the
--- rows it offered, as shown.
---@param label? string
---@return string[]
local function pick(label)
  local select = vim.ui.select
  local rows, calls = nil, 0
  vim.ui.select = function(items, opts, on_choice)
    calls = calls + 1
    if calls > 1 then
      return on_choice(nil)
    end
    rows = vim.tbl_map(opts.format_item, items)
    for i, row in ipairs(rows) do
      if label and vim.endswith(row, " " .. label) then
        return on_choice(items[i])
      end
    end
    on_choice(nil)
  end
  local ok, err = pcall(function()
    vim.api.nvim_feedkeys(vim.g.mapleader .. "uy", "mx", false)
    settle()
  end)
  vim.ui.select = select
  assert(ok, err)
  return assert(rows, "<leader>uy offered nothing")
end

h.test("turning parameters on makes them italic in their own colour, and saves it", function()
  h.with_state('{"theme":"tokyonight-moon"}', function()
    h.apply_theme("tokyonight-moon")
    local before = hl("@variable.parameter")
    h.eq(false, italic("@variable.parameter"), "parameters before")
    pick("parameters")
    h.eq(true, italic("@variable.parameter"), "parameters after")
    h.eq(true, italic("@variable.parameter.builtin"), "built-in parameters after")
    h.eq(before.fg, hl("@variable.parameter").fg, "parameters' colour")
    h.eq({ parameters = true }, saved().extra_italics)
  end)
end)

h.test("turning parameters off gives them back the theme's own look, and saves it", function()
  h.with_state('{"theme":"tokyonight-moon","extra_italics":{"parameters":true}}', function()
    h.apply_theme("tokyonight-moon")
    h.eq(true, italic("@variable.parameter"), "parameters before")
    pick("parameters")
    h.eq(false, italic("@variable.parameter"), "parameters after")
    h.eq({ parameters = false }, saved().extra_italics)
  end)
end)

h.test("Extra italics are shared by every theme", function()
  h.with_state('{"theme":"tokyonight-moon","extra_italics":{"parameters":true}}', function()
    for _, theme in ipairs({ "catppuccin-mocha", "tokyonight-moon", "habamax" }) do
      h.apply_theme(theme)
      h.eq(true, italic("@variable.parameter"), "parameters on " .. theme)
    end
  end)
end)

h.test("a fresh start restores the Extra italics", function()
  h.with_state('{"theme":"catppuccin-mocha","extra_italics":{"parameters":true}}', function()
    local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
    local cmd = { "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }
    local env = {
      TEST_SPEC = root .. "/tests/theme/boot.lua",
      EXPECT_THEME = "catppuccin-mocha",
      EXPECT_ITALIC = vim.json.encode({ ["@variable.parameter"] = true }),
    }
    local result = vim.system(cmd, { env = env, text = true }):wait(60000)
    h.eq(0, result.code, "second instance:\n" .. (result.stdout or "") .. (result.stderr or ""))
  end)
end)

h.test("a saved state from before Extra italics loads cleanly and changes nothing", function()
  h.with_state('{"theme":"tokyonight-moon","italics":{"tokyonight":{"comments":true}}}', function()
    h.apply_theme("tokyonight-moon")
    h.eq(false, italic("@variable.parameter"), "parameters")
    h.eq(true, italic("Comment"), "the theme's own comments")
    h.eq({}, h.errors())
  end)
end)

h.test("a parameter highlight a plugin defines later is italic too, and its neighbours aren't", function()
  h.with_state('{"theme":"tokyonight-moon","extra_italics":{"parameters":true}}', function()
    h.apply_theme("tokyonight-moon")
    vim.api.nvim_set_hl(0, "@variable.parameter.lua", { fg = "#123456" })
    vim.api.nvim_set_hl(0, "@variable.parameterish", { fg = "#123456" })
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad" })
    settle()
    h.eq(true, italic("@variable.parameter.lua"), "Lua parameters")
    h.eq("#123456", ("#%06x"):format(hl("@variable.parameter.lua").fg), "Lua parameters' colour")
    h.eq(false, italic("@variable.parameterish"), "a group that only starts the same")
    h.eq(false, italic("@variable"), "plain variables")
  end)
end)

h.test("with Extra italics on, line diagnostics and Breadcrumbs stay italic and transparency holds", function()
  h.with_state('{"theme":"tokyonight-moon","extra_italics":{"parameters":true}}', function()
    h.apply_theme("tokyonight-moon")
    h.eq(true, italic("DiagnosticVirtualTextError"), "line diagnostics")
    h.eq(true, italic("WinBar"), "Breadcrumbs")
    h.eq(nil, hl("Normal").bg, "the editor background")
  end)
end)
