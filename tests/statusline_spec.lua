local h = require("harness")
local icons = require("util.icons")

h.attach_ui(160, 30)

-- A git repo on a known branch, with a committed file of a known size (2.9k,
-- in short lines: long ones make it a "bigfile") a few folders down, and a Lua
-- file for the language server.
local repo = vim.fn.tempname()
vim.fn.mkdir(repo .. "/src/deep", "p")
repo = assert(vim.uv.fs_realpath(repo))
local file = repo .. "/src/deep/tracked.txt"
vim.fn.writefile(vim.fn["repeat"]({ ("x"):rep(99) }, 30), file)
local lua_file = repo .. "/init.lua"
vim.fn.writefile({ "local x = 1", "return x" }, lua_file)
local function git(...)
  local result = vim.system({ "git", "-C", repo, ... }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
git("init", "-b", "statusline-branch")
git("add", ".")
git("-c", "user.name=test", "-c", "user.email=test@example.com", "commit", "-m", "init")
vim.fn.chdir(repo)

--- Poll the statusline until `ok(text)` holds, then return its text.
---@param ok fun(text: string): boolean
local function wait_for_statusline(ok)
  local text = ""
  vim.wait(5000, function()
    text = h.statusline()
    return ok(text)
  end, 50)
  return text
end

local function contains(text, part)
  return text:find(part, 1, true) ~= nil
end

--- Edit the file with a line added, so there's an uncommitted diff. Reloaded
--- each time (with an attached UI, `:edit` of a changed buffer waits at its error).
local function editing_changed_file()
  pcall(vim.cmd, "Neotree close")
  vim.cmd.edit({ file, bang = true })
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { "added" })
end

--- The statusline lualine draws now, with a way to ask the foreground colour
--- ("#rrggbb") it draws `text` in. The screen doesn't give colours, and a mode
--- may only last as long as the keys typed, so this draws lualine's statusline
--- itself.
local function drawn()
  local result = vim.api.nvim_eval_statusline(require("lualine").statusline(true), { highlights = true })
  return {
    str = result.str,
    colour = function(text)
      local at = assert(result.str:find(text, 1, true), ("no %q in: %s"):format(text, result.str)) - 1
      local group
      for _, hl in ipairs(result.highlights) do
        if hl.start <= at then
          group = hl.group
        end
      end
      local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
      return fg and ("#%06x"):format(fg)
    end,
  }
end

--- What `drawn()` gives after typing `keys` (then <Esc>), in the mode they leave.
local function drawn_after(keys)
  local result
  _G.statusline_spec_capture = function()
    result = drawn()
  end
  vim.api.nvim_feedkeys(vim.keycode(keys .. "<Cmd>lua statusline_spec_capture()<CR><Esc>"), "nx", false)
  _G.statusline_spec_capture = nil
  return result
end

--- A highlight group's foreground in the current theme, as "#rrggbb".
local function fg(group)
  local value = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
  return value and ("#%06x"):format(value)
end

h.test("for a file in a git repo, it shows the mode icon, file size, branch and diff, with no chevrons", function()
  editing_changed_file()
  local parts = {
    vim.trim(icons.separators.honeycomb.right),
    "2.9k",
    "statusline-branch",
    vim.trim(icons.git.added) .. " 1",
  }
  local text = wait_for_statusline(function(text)
    return vim.iter(parts):all(function(part)
      return contains(text, part)
    end)
  end)
  for _, part in ipairs(parts) do
    h.eq(true, contains(text, part), ("statusline shows %q\nstatusline: %s"):format(part, text))
  end
  for _, chevron in ipairs({ "\u{e0b1}", "\u{e0b3}" }) do -- lualine's defaults
    h.eq(false, contains(text, chevron), ("no %q\nstatusline: %s"):format(chevron, text))
  end
end)

h.test("the filename is shown, alone and centred between the left and right items", function()
  h.with_state(nil, function()
    editing_changed_file()
    local text = wait_for_statusline(function(text)
      return contains(text, "tracked.txt") and contains(text, "2.9k")
    end)
    h.eq(true, contains(text, "tracked.txt"), "filename shown by default\nstatusline: " .. text)
    h.eq(false, contains(text, "deep"), "no path\nstatusline: " .. text)

    -- The filetype icon, a space, then the name.
    local glyph = require("mini.icons").get("file", file)
    local first = assert(text:find(glyph .. " tracked.txt", 1, true), "icon before the name: " .. text)
    local after = first + #(glyph .. " tracked.txt")
    local left_gap = #text:sub(1, first - 1):match(" *$")
    local right_gap = #text:sub(after):match("^ *")
    local centred = math.abs(left_gap - right_gap) <= 1
    h.eq(true, centred, ("centred: %d spaces left, %d right\nstatusline: %s"):format(left_gap, right_gap, text))
  end)
end)

h.test("<leader>uN hides the filename, and a second boot keeps it hidden", function()
  h.with_state(nil, function()
    editing_changed_file()
    wait_for_statusline(function(text)
      return contains(text, "tracked.txt")
    end)

    -- Unmapped, the keys would leave which-key waiting for more.
    h.eq(true, vim.fn.maparg(vim.g.mapleader .. "uN", "n") ~= "", "<leader>uN is mapped")
    vim.api.nvim_feedkeys(vim.g.mapleader .. "uN", "mx", false)
    local text = wait_for_statusline(function(text)
      return contains(text, "2.9k") and not contains(text, "tracked.txt")
    end)
    h.eq(false, contains(text, "tracked.txt"), "no filename after <leader>uN\nstatusline: " .. text)

    local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
    local cmd = { "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }
    local env = { TEST_SPEC = root .. "/tests/statusline/boot.lua", EXPECT_FILE = file, EXPECT_FILENAME = "hidden" }
    local result = vim.system(cmd, { env = env, text = true }):wait(60000)
    h.eq(0, result.code, "second instance:\n" .. (result.stdout or "") .. (result.stderr or ""))

    vim.api.nvim_feedkeys(vim.g.mapleader .. "uN", "mx", false)
    text = wait_for_statusline(function(text)
      return contains(text, "tracked.txt")
    end)
    h.eq(true, contains(text, "tracked.txt"), "filename back after a second <leader>uN\nstatusline: " .. text)
  end)
end)

h.test("it's blank while the Explorer is focused", function()
  editing_changed_file()
  wait_for_statusline(function(text)
    return contains(text, "2.9k")
  end)
  h.eq(true, h.focus_explorer(), "the Explorer has focus")
  local text = wait_for_statusline(function(text)
    return vim.trim(text) == ""
  end)
  h.eq("", vim.trim(text), "statusline with the Explorer focused")

  vim.cmd("Neotree close")
  text = wait_for_statusline(function(text)
    return contains(text, "2.9k")
  end)
  h.eq(true, contains(text, "2.9k"), "statusline back after closing the Explorer\nstatusline: " .. text)
end)

h.test("after switching theme, the mode icon and filename follow the new theme's Mode colours", function()
  h.with_state(nil, function()
    editing_changed_file()
    -- Each theme's insert and copy colours (see tint_spec). Copy shows while
    -- `y` waits for a motion, where lualine's own colour would be normal mode's.
    for theme, colours in pairs({
      ["tokyonight-moon"] = { insert = "#c3e88d", copy = "#ffc777" },
      ["catppuccin-mocha"] = { insert = "#a6e3a1", copy = "#f9e2af" },
    }) do
      h.apply_theme(theme)
      local insert = drawn_after("i")
      h.eq(colours.insert, insert.colour(vim.trim(icons.modes.insert)), theme .. " insert-mode icon")
      h.eq(colours.insert, insert.colour("tracked.txt"), theme .. " insert-mode filename")
      local copy = drawn_after("y")
      h.eq(colours.copy, copy.colour(vim.trim(icons.separators.honeycomb.right)), theme .. " icon while copying")
      h.eq(colours.copy, copy.colour("tracked.txt"), theme .. " filename while copying")
      local normal = drawn()
      local icon = normal.colour(vim.trim(icons.separators.honeycomb.right))
      h.eq(icon, normal.colour("tracked.txt"), theme .. " normal-mode filename")
    end
  end)
end)

h.test("every other item has its own colour, its text matching its icon, in every mode", function()
  editing_changed_file()
  h.apply_theme("tokyonight-moon")
  -- Each item's icon, and text it shows.
  local items = {
    file_size = { vim.trim(icons.ui.Code), "2.9k" },
    branch = { vim.trim(icons.git.Branch), "statusline-branch" },
    position = { vim.trim(icons.misc.location_point), "Top" },
    clock = { vim.trim(icons.ui.Clock), os.date("%R") },
  }
  local normal, insert = drawn(), drawn_after("i")
  local seen = {}
  for item, parts in pairs(items) do
    local icon, text = unpack(parts)
    local colour = normal.colour(icon)
    h.eq(nil, seen[colour], ("%s's colour %s is its own"):format(item, colour))
    seen[colour] = item
    h.eq(colour, normal.colour(text), item .. "'s text matches its icon")
    h.eq(colour, insert.colour(icon), item .. "'s icon in insert mode")
    h.eq(colour, insert.colour(text), item .. "'s text in insert mode")
  end
end)

h.test("the filename's icon keeps the file's own colour", function()
  editing_changed_file()
  local glyph, group = require("mini.icons").get("file", file)
  h.eq(fg(group), drawn().colour(glyph .. " tracked.txt"), "filename icon")
end)

h.test("the scrollbar's eight blocks each have their own colour, down to the last line", function()
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn["repeat"]({ "line" }, 80))
  local blocks = { "█", "▇", "▆", "▅", "▄", "▃", "▂", "▁" }
  local seen = {}
  for i, block in ipairs(blocks) do
    vim.api.nvim_win_set_cursor(0, { i * 10, 0 }) -- the last line of each eighth
    local colour = drawn().colour(block)
    h.eq(nil, seen[colour], ("block %d's colour %s is its own"):format(i, colour))
    seen[colour] = i
  end
  vim.cmd.bwipeout({ bang = true })
end)

h.test("the filetype on the right says whether a language server is working", function()
  h.apply_theme("tokyonight-moon")
  vim.cmd.edit(lua_file)
  local buf = vim.api.nvim_get_current_buf()
  local attached = vim.wait(20000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = "lua_ls" }) > 0
  end, 100)
  h.eq(true, attached, "lua_ls attached")
  -- The filetype on the right: the file's icon and the filetype (the centre
  -- has "init.lua").
  local lua = require("mini.icons").get("file", lua_file) .. " lua"
  h.eq(fg("DiagnosticOk"), drawn().colour(lua), "filetype with lua_ls attached")

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    client:stop(true)
  end
  vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = buf }) == 0
  end, 50)
  h.eq(fg("DiagnosticError"), drawn().colour(lua), "filetype with its server stopped")

  editing_changed_file()
  local text = require("mini.icons").get("file", file) .. " text"
  h.eq(fg("Comment"), drawn().colour(text), "filetype with no server")
end)
