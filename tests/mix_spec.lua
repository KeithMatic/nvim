local h = require("harness")

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- `group`'s definition, links followed.
local function hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

--- `group`'s `attr` colour as "#rrggbb", links followed.
local function color(group, attr)
  local value = hl(group)[attr]
  return value and ("#%06x"):format(value)
end

--- The theme saved in the state file.
local function saved_theme()
  local ok, state = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state_file), "\n"))
  end)
  return ok and state.theme or nil
end

local function settle()
  vim.wait(300, function()
    return false
  end)
end

--- Apply the Mix and wait until it's drawn: on a cold cache converge reads its
--- themes first, on the next tick.
local function apply_mix()
  vim.cmd.colorscheme("converge")
  vim.wait(10000, function()
    return vim.g.colors_name == "converge"
  end, 50)
  h.eq("converge", vim.g.colors_name, "the Mix applied")
  settle()
end

--- Forget every theme converge has read, so the next Mix reads them again.
local function cold_cache()
  require("converge.cache").clear()
  require("converge.snapshots").clear()
end

--- Boot a second headless Neovim on this config and assert that it starts with
--- `theme` and no errors (see theme_spec.lua).
local function assert_boots_with(theme)
  local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
  local cmd = { "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }
  local env = { TEST_SPEC = root .. "/tests/theme/boot.lua", EXPECT_THEME = theme }
  local result = vim.system(cmd, { env = env, text = true }):wait(60000)
  h.eq(0, result.code, "second instance:\n" .. (result.stdout or "") .. (result.stderr or ""))
end

--- A local theme plugin: <prefix>-dark and <prefix>-dim (dark), <prefix>-light
--- (light), on the runtimepath as lazy.nvim would put it once loaded. A new
--- `prefix` gives themes converge hasn't read this session.
---@param prefix? string default: "fixture"
local function fixture_plugin(prefix)
  prefix = prefix or "fixture"
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. "/colors", "p")
  local function theme(name, background, normal)
    vim.fn.writefile({
      'vim.cmd("hi clear")',
      ("vim.o.background = %q"):format(background),
      ("vim.g.colors_name = %q"):format(name),
      "local function hl(name, val) vim.api.nvim_set_hl(0, name, val) end",
      ('hl("Normal", { fg = "#d0d0d0", bg = %q })'):format(normal),
      'hl("String", { fg = "#00c000" })',
      'hl("Keyword", { fg = "#c000c0" })',
      'hl("DiagnosticError", { fg = "#e00000" })',
      'hl("DiagnosticWarn", { fg = "#e0c000" })',
      'hl("Function", { fg = "#0060e0" })',
      'hl("Constant", { fg = "#e08000" })',
    }, ("%s/colors/%s.lua"):format(dir, name))
  end
  theme(prefix .. "-dark", "dark", "#101820")
  theme(prefix .. "-dim", "dark", "#202020")
  theme(prefix .. "-light", "light", "#f0f0f0")
  vim.opt.rtp:append(dir)
  return dir
end

--- Open the Theme italics picker (<leader>uy), flip the row whose text ends
--- with `label`, and close it when it reopens. Returns the rows it offered.
---@param label string
---@return string[]
local function pick_italic(label)
  local select = vim.ui.select
  local rows, calls = nil, 0
  vim.ui.select = function(items, opts, on_choice)
    calls = calls + 1
    if calls > 1 then
      return on_choice(nil)
    end
    rows = vim.tbl_map(opts.format_item, items)
    for i, row in ipairs(rows) do
      if vim.endswith((row:gsub("%s+", " ")), " " .. label) then
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

h.test("the Mix takes its UI from tokyonight-moon and its code colours from catppuccin-mocha", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-moon")
    local ui = { LineNr = color("LineNr", "fg"), Pmenu = color("Pmenu", "fg") }
    h.apply_theme("catppuccin-mocha")
    local syntax = { Function = color("Function", "fg"), String = color("String", "fg") }
    apply_mix()
    h.eq(ui, { LineNr = color("LineNr", "fg"), Pmenu = color("Pmenu", "fg") }, "UI groups")
    h.eq(syntax, { Function = color("Function", "fg"), String = color("String", "fg") }, "syntax groups")
  end)
end)

h.test("the Mix's background and Mode colours come from its UI theme, its brackets from its syntax theme", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    apply_mix()
    local theme = require("theme")
    local moon = require("tokyonight.colors").setup({ style = "moon" })
    local mocha = require("catppuccin.palettes").get_palette("mocha")
    h.eq(moon.bg, theme.background, "background")
    h.eq(theme.blend(theme.tint.color, moon.bg, theme.tint.fade), color("CursorLine", "bg"), "the Tint")
    h.eq(moon.green:lower(), theme.mode_color("insert"), "insert")
    h.eq(moon.magenta:lower(), theme.mode_color("visual"), "visual")
    h.eq(mocha.yellow:lower(), color("RainbowBracket1", "fg"), "outer brackets")
    h.eq(mocha.mauve:lower(), color("RainbowBracket2", "fg"), "middle brackets")
    h.eq(mocha.blue:lower(), color("RainbowBracket3", "fg"), "inner brackets")
  end)
end)

h.test("the Mix keeps Transparency", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    apply_mix()
    for _, group in ipairs({ "Normal", "NormalFloat", "SignColumn", "StatusLine" }) do
      h.eq(nil, color(group, "bg"), group .. " background")
    end
  end)
end)

h.test("<leader>uC lists the Mix by its pair, and applies it", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    vim.api.nvim_feedkeys(vim.g.mapleader .. "uC", "mx", false)
    local picker
    vim.wait(5000, function()
      picker = Snacks.picker.get({ source = "colorschemes" })[1]
      return picker ~= nil and not picker:is_active()
    end, 50)
    assert(picker, "<leader>uC opened no colorscheme picker")
    settle()
    local lines = vim.api.nvim_buf_get_lines(picker.list.win.buf, 0, -1, false)
    local labelled = vim.tbl_filter(function(line)
      return line:find("tokyonight-moon + catppuccin-mocha", 1, true) ~= nil
    end, lines)
    picker:close()
    vim.wait(2000, function()
      return vim.g.colors_name == "tokyonight-night"
    end, 50)
    h.eq(1, #labelled, "one line shows the Mix's pair:\n" .. table.concat(lines, "\n"))
  end)
end)

h.test("the Mix is restored on the next start", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    apply_mix()
    h.eq("converge", saved_theme(), "saved")
    assert_boots_with("converge")
  end)
end)

h.test("reading the Mix's themes saves none of them as the theme", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    cold_cache()
    local seen = {}
    local id = vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        seen[saved_theme() or "(none)"] = true
      end,
    })
    local ok, err = pcall(apply_mix)
    vim.api.nvim_del_autocmd(id)
    assert(ok, err)
    local names = vim.tbl_keys(seen)
    table.sort(names)
    h.eq({ "converge", "tokyonight-night" }, names, "every theme ever saved")
  end)
end)

h.test(":Converge doesn't exist, so no recipe can be saved over the config's", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    apply_mix()
    h.eq(0, vim.fn.exists(":Converge"))
  end)
end)

h.test("Theme italics on the Mix offer its syntax theme's family, and rebuild it", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    apply_mix()
    h.eq(false, hl("Repeat").italic == true, "loops before")
    local rows = pick_italic("loops")
    local sections = {}
    for _, row in ipairs(rows) do
      sections[row:match("^%S+%s+(%S+)")] = true
    end
    h.eq({ catppuccin = true, extra = true }, sections, "the picker's sections")
    vim.wait(10000, function()
      return vim.g.colors_name == "converge" and hl("Repeat").italic == true
    end, 50)
    h.eq(true, hl("Repeat").italic == true, "loops after")
  end)
end)

h.test("a Theme italics change on a family's theme reaches the Mix, even when it isn't applied", function()
  h.with_state(nil, function()
    -- Loops on (nothing saved: off, so the flip turns them on, whatever an
    -- earlier test left catppuccin set up with), and the Mix read with them.
    h.apply_theme("catppuccin-mocha")
    pick_italic("loops")
    h.apply_theme("tokyonight-night")
    apply_mix()
    h.eq(true, hl("Repeat").italic == true, "loops on the Mix before")
    -- Loops off on catppuccin-mocha itself, the Mix not applied.
    h.apply_theme("catppuccin-mocha")
    pick_italic("loops")
    h.eq(false, hl("Repeat").italic == true, "loops on catppuccin-mocha")
    h.apply_theme("tokyonight-night")
    apply_mix()
    vim.wait(10000, function()
      return hl("Repeat").italic ~= true
    end, 50)
    h.eq(false, hl("Repeat").italic == true, "loops on the Mix after")
  end)
end)

h.test("the Mix's label counts its overrides", function()
  local mix = require("mix")
  local pair = { ui = "tokyonight-moon", syntax = "catppuccin-mocha" }
  h.eq("tokyonight-moon + catppuccin-mocha", mix.label(pair), "none")
  h.eq(
    "tokyonight-moon + catppuccin-mocha · 1 override",
    mix.label(vim.tbl_extend("force", pair, { overrides = { set = { Comment = { fg = "#ff0000" } } } })),
    "one"
  )
  h.eq(
    "tokyonight-moon + catppuccin-mocha · 3 overrides",
    mix.label(vim.tbl_extend("force", pair, {
      overrides = { from = { ["tokyonight-night"] = { "Comment", "String" } }, set = { Title = { bold = true } } },
    })),
    "from and set"
  )
end)

h.test("the configured Mix names only Curated themes and overrides nothing the config sets", function()
  h.eq({}, require("mix").problems())
end)

h.test("a Mix naming a theme that isn't a Curated theme is reported, and falls back", function()
  local mix = require("mix")
  local bad = { ui = "no-such-ui", syntax = "no-such-syntax" }
  local problems = table.concat(mix.problems(bad), "\n")
  h.eq(true, problems:find("no-such-ui", 1, true) ~= nil, "the UI theme is named:\n" .. problems)
  h.eq(true, problems:find("no-such-syntax", 1, true) ~= nil, "the syntax theme is named:\n" .. problems)
  local recipe = mix.recipe(bad)
  h.eq({ "tokyonight-moon", "tokyonight-moon" }, { recipe.ui, recipe.syntax }, "the fallback")
  recipe = mix.recipe({ ui = "catppuccin-frappe", syntax = "no-such-syntax" })
  h.eq({ "catppuccin-frappe", "catppuccin-frappe" }, { recipe.ui, recipe.syntax }, "a bad syntax theme")
end)

h.test("an override on something the config sets is reported, others aren't", function()
  local problems = require("mix").problems({
    ui = "tokyonight-moon",
    syntax = "catppuccin-mocha",
    overrides = {
      set = {
        CursorLine = { bg = "#000000" }, -- the Tint
        NormalFloat = { bg = "#000000" }, -- Transparency
        RainbowBracket1 = { fg = "#ff0000" }, -- the Rainbow brackets
        Normal = { fg = "#ffffff" }, -- Transparency only clears the background
        Comment = { fg = "#ff0000" },
      },
    },
  })
  local text = table.concat(problems, "\n")
  h.eq(3, #problems, "three reported:\n" .. text)
  for _, group in ipairs({ "CursorLine", "NormalFloat", "RainbowBracket1" }) do
    h.eq(true, text:find(group, 1, true) ~= nil, group .. " reported:\n" .. text)
  end
end)

h.test(
  "an added plugin's dark themes are Curated themes and its light ones aren't, without changing the theme",
  function()
    h.with_state(nil, function()
      h.apply_theme("tokyonight-night")
      local added = { { dir = fixture_plugin() } }
      local theme = require("theme")
      theme.detect(added)
      local curated = theme.curated(added)
      h.eq(true, vim.list_contains(curated, "fixture-dark"), "fixture-dark offered")
      h.eq(true, vim.list_contains(curated, "fixture-dim"), "fixture-dim offered")
      h.eq(false, vim.list_contains(curated, "fixture-light"), "fixture-light offered")
      h.eq(true, vim.list_contains(curated, "converge"), "the Mix offered")
      h.eq("tokyonight-night", vim.g.colors_name, "the theme is back")
      h.eq("dark", vim.o.background, "the background is back")
      h.eq("tokyonight-night", saved_theme(), "nothing saved")
    end)
  end
)

h.test("a `from` override, or a `set` link, on something the config sets is reported", function()
  local problems = require("mix").problems({
    ui = "tokyonight-moon",
    syntax = "catppuccin-mocha",
    overrides = {
      from = { ["tokyonight-night"] = { "CursorLine", "Comment" } }, -- the Tint; nothing
      set = { NormalFloat = { link = "Normal" } }, -- Transparency
    },
  })
  local text = table.concat(problems, "\n")
  h.eq(2, #problems, "two reported:\n" .. text)
  for _, group in ipairs({ "CursorLine", "NormalFloat" }) do
    h.eq(true, text:find(group, 1, true) ~= nil, group .. " reported:\n" .. text)
  end
end)

h.test("a `from` theme that isn't a Curated theme is reported", function()
  local problems = require("mix").problems({
    ui = "tokyonight-moon",
    syntax = "catppuccin-mocha",
    overrides = { from = { ["no-such-theme"] = { "Comment" } } },
  })
  local text = table.concat(problems, "\n")
  h.eq(1, #problems, "one reported:\n" .. text)
  h.eq(true, text:find("no-such-theme", 1, true) ~= nil, "it's named:\n" .. text)
end)

h.test(
  "an added theme can be half of the Mix before it's read and once it's found dark, never once found light",
  function()
    h.with_state(nil, function()
      h.apply_theme("tokyonight-night")
      local added = { { dir = fixture_plugin("unread") } }
      local theme = require("theme")
      h.eq(true, theme.is_curated("unread-light", added), "a theme not read yet")
      theme.detect(added)
      h.eq(true, theme.is_curated("unread-dark", added), "a dark one")
      h.eq(false, theme.is_curated("unread-light", added), "a light one")
      h.eq(false, theme.is_curated("converge", added), "the Mix itself")
      h.eq(true, theme.is_curated("catppuccin-mocha", added), "a built-in one")
    end)
  end
)

h.test("variants narrows an added plugin's themes", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    local added = { { dir = fixture_plugin(), variants = { "fixture-dim" } } }
    local theme = require("theme")
    theme.detect(added)
    local curated = theme.curated(added)
    h.eq(true, vim.list_contains(curated, "fixture-dim"), "fixture-dim offered")
    h.eq(false, vim.list_contains(curated, "fixture-dark"), "fixture-dark offered")
  end)
end)

h.test("an added theme is read once, then known", function()
  h.with_state(nil, function()
    h.apply_theme("tokyonight-night")
    local added = { { dir = fixture_plugin() } }
    local theme = require("theme")
    theme.detect(added)
    local applied = 0
    local id = vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        applied = applied + 1
      end,
    })
    theme.detect(added)
    vim.api.nvim_del_autocmd(id)
    h.eq(0, applied, "themes applied by the second check")
  end)
end)

h.test("a theme with no family takes its Mode colours and brackets from its own groups", function()
  h.with_state(nil, function()
    fixture_plugin()
    h.apply_theme("fixture-dark")
    local theme = require("theme")
    h.eq("#101820", theme.background, "background")
    h.eq(theme.blend(theme.tint.color, "#101820", theme.tint.fade), color("CursorLine", "bg"), "the Tint")
    h.eq({
      insert = "#00c000",
      visual = "#c000c0",
      delete = "#e00000",
      copy = "#e0c000",
      normal = "#0060e0",
      command = "#e08000",
    }, {
      insert = theme.mode_color("insert"),
      visual = theme.mode_color("visual"),
      delete = theme.mode_color("delete"),
      copy = theme.mode_color("copy"),
      normal = theme.mode_color("normal"),
      command = theme.mode_color("command"),
    }, "Mode colours")
    h.eq(
      { "#e0c000", "#c000c0", "#0060e0" },
      { color("RainbowBracket1", "fg"), color("RainbowBracket2", "fg"), color("RainbowBracket3", "fg") },
      "Rainbow brackets"
    )
    h.apply_theme("tokyonight-night")
  end)
end)

h.test("an added repo becomes a lazy-loaded plugin, with its opts and without variants", function()
  h.eq(
    {
      { "rebelot/kanagawa.nvim", lazy = true },
      { "folke/other.nvim", lazy = true, opts = { transparent = true } },
    },
    require("theme").added_specs({
      "rebelot/kanagawa.nvim",
      { "folke/other.nvim", variants = { "other-night" }, opts = { transparent = true } },
    })
  )
end)
