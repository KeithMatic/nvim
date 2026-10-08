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
      if label and vim.endswith((row:gsub("%s+", " ")), " " .. label) then
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

-- Every Extra italic, as the picker shows it, and the highlight names it makes
-- italic (from the spec, #4).
local extras = {
  { "comments", { "Comment", "@comment" } },
  { "documentation comments", { "@comment.documentation", "@string.documentation" } },
  { "keywords", { "Keyword", "Statement", "@keyword", "@keyword.function" } },
  { "conditionals", { "Conditional", "@keyword.conditional", "@keyword.conditional.ternary" } },
  { "loops", { "Repeat", "@keyword.repeat" } },
  { "return and exception keywords", { "@keyword.return", "@keyword.exception", "Exception" } },
  { "imports", { "Include", "@keyword.import" } },
  { "functions", { "Function", "@function", "@function.call" } },
  { "methods", { "@function.method", "@function.method.call" } },
  { "variables", { "Identifier", "@variable" } },
  { "parameters", { "@variable.parameter", "@variable.parameter.builtin" } },
  { "properties", { "@property", "@variable.member" } },
  {
    "built-ins (self, this)",
    { "@variable.builtin", "@function.builtin", "@type.builtin", "@constant.builtin", "@module.builtin" },
  },
  { "types", { "Type", "@type", "@type.definition" } },
  { "constants", { "Constant", "@constant", "@constant.macro" } },
  { "modules", { "@module" } },
  { "decorators", { "@attribute", "@attribute.builtin" } },
  { "strings", { "String", "@string" } },
  { "characters and escapes", { "Character", "@character", "@string.escape", "SpecialChar" } },
  { "numbers", { "Number", "Float", "@number", "@number.float" } },
  { "booleans", { "Boolean", "@boolean" } },
  { "operators", { "Operator", "@operator", "@keyword.operator" } },
  { "markup tags and attributes", { "@tag", "@tag.attribute" } },
}

-- The options each curated family offers itself, so its extras are hidden.
local offered = {
  tokyonight = { "comments", "keywords", "functions", "variables" },
  catppuccin = {
    "comments",
    "conditionals",
    "loops",
    "functions",
    "keywords",
    "strings",
    "variables",
    "numbers",
    "booleans",
    "properties",
    "types",
    "operators",
  },
}

--- A picker row without its on/off icon, spaces collapsed.
local function text(row)
  return (row:match("^%S+%s+(.*)$"):gsub("%s+", " "))
end

--- The extras' labels, without those `hidden`.
local function visible_extras(hidden)
  local ret = {}
  for _, extra in ipairs(extras) do
    if not vim.list_contains(hidden or {}, extra[1]) then
      table.insert(ret, extra[1])
    end
  end
  return ret
end

--- A state with every Extra italic on (as saved, by name).
local function all_on(theme)
  return vim.json.encode({
    theme = theme,
    extra_italics = {
      comments = true,
      documentation = true,
      keywords = true,
      conditionals = true,
      loops = true,
      returns = true,
      imports = true,
      functions = true,
      methods = true,
      variables = true,
      parameters = true,
      properties = true,
      builtins = true,
      types = true,
      constants = true,
      modules = true,
      decorators = true,
      strings = true,
      characters = true,
      numbers = true,
      booleans = true,
      operators = true,
      tags = true,
    },
  })
end

for _, case in ipairs({
  { theme = "tokyonight-moon", family = "tokyonight" },
  { theme = "catppuccin-mocha", family = "catppuccin" },
  { theme = "habamax" },
}) do
  h.test(case.theme .. ": every Extra italic it doesn't offer makes its highlight names italic", function()
    h.with_state(all_on(case.theme), function()
      h.apply_theme(case.theme)
      local hidden = offered[case.family] or {}
      for _, extra in ipairs(extras) do
        if not vim.list_contains(hidden, extra[1]) then
          for _, group in ipairs(extra[2]) do
            h.eq(true, italic(group), extra[1] .. ": " .. group)
          end
        end
      end
    end)
  end)
end

h.test("each Extra italic keeps to its own highlight names", function()
  h.with_state('{"theme":"habamax","extra_italics":{"functions":true,"variables":true}}', function()
    h.apply_theme("habamax")
    h.eq(true, italic("@function"), "functions")
    h.eq(true, italic("@variable"), "variables")
    for _, group in ipairs({ "@function.builtin", "@function.method", "@variable.parameter", "@variable.builtin" }) do
      h.eq(false, italic(group), group)
    end
  end)
end)

h.test("an extra the theme offers itself is left to the theme", function()
  h.with_state('{"theme":"tokyonight-moon","extra_italics":{"comments":true}}', function()
    h.apply_theme("tokyonight-moon")
    -- tokyonight's own comments option is on by default; turn it off.
    pick("tokyonight comments")
    h.eq(false, italic("Comment"), "comments on tokyonight, its own option off")
    h.apply_theme("habamax")
    h.eq(true, italic("Comment"), "comments on a theme that doesn't offer them")
  end)
end)

h.test("tokyonight: its own options first, then the extras it doesn't offer", function()
  h.with_state('{"theme":"tokyonight-moon"}', function()
    h.apply_theme("tokyonight-moon")
    local expected = {}
    for _, option in ipairs(offered.tokyonight) do
      table.insert(expected, "tokyonight " .. option)
    end
    for _, label in ipairs(visible_extras(offered.tokyonight)) do
      table.insert(expected, "extra " .. label)
    end
    h.eq(expected, vim.tbl_map(text, pick()))
  end)
end)

h.test("catppuccin: its own options first, then the extras it doesn't offer", function()
  h.with_state('{"theme":"catppuccin-mocha"}', function()
    h.apply_theme("catppuccin-mocha")
    local expected = {}
    for _, option in ipairs(offered.catppuccin) do
      table.insert(expected, "catppuccin " .. option)
    end
    for _, label in ipairs(visible_extras(offered.catppuccin)) do
      table.insert(expected, "extra " .. label)
    end
    h.eq(expected, vim.tbl_map(text, pick()))
  end)
end)

h.test("a theme outside the curated families offers only the extras, with no warning", function()
  h.with_state('{"theme":"habamax"}', function()
    h.apply_theme("habamax")
    local expected = vim.tbl_map(function(label)
      return "extra " .. label
    end, visible_extras())
    h.eq(expected, vim.tbl_map(text, pick("types")))
    h.eq(true, italic("@type"), "types after flipping on habamax")
    h.eq({}, h.errors())
  end)
end)

h.test("an italic parameter stays italic once a language server colours it", function()
  h.with_state('{"theme":"tokyonight-moon","extra_italics":{"parameters":true}}', function()
    h.apply_theme("tokyonight-moon")
    local file = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "local function greet(name)", "  return name", "end", "return greet" }, file)
    vim.cmd.edit(file)
    local buf = vim.api.nvim_get_current_buf()
    local col = assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("name")) - 1
    local pos
    local coloured = vim.wait(20000, function()
      pos = vim.inspect_pos(buf, 0, col)
      return #pos.semantic_tokens > 0
    end, 100)
    local ok, err = pcall(function()
      h.eq(true, coloured, "lua_ls coloured the parameter")
      local syntax = vim.tbl_map(function(item)
        return item.hl_group_link or item.hl_group
      end, pos.treesitter)
      h.eq(
        true,
        vim.iter(pos.treesitter):any(function(item)
          return italic(item.hl_group)
        end),
        "an italic syntax highlight under it: " .. vim.inspect(syntax)
      )
      -- The language server's highlights combine with it, unless one says not to.
      for _, token in ipairs(pos.semantic_tokens) do
        h.eq(nil, hl(token.opts.hl_group).nocombine, token.opts.hl_group .. " combines")
      end
    end)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      client:stop(true)
    end
    vim.cmd("bwipeout!")
    assert(ok, err)
  end)
end)
