local h = require("harness")
local icons = require("util.icons")

h.attach_ui(160, 30)

-- A git repo on a known branch, with a committed file of a known size (2.9k).
local repo = vim.fn.tempname()
vim.fn.mkdir(repo, "p")
repo = assert(vim.uv.fs_realpath(repo))
local file = repo .. "/tracked.txt"
vim.fn.writefile({ ("x"):rep(2999) }, file)
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

h.test("for a file in a git repo, it shows the mode icon, file size, branch and diff", function()
  editing_changed_file()
  local parts = {
    vim.trim(icons.modes.normal),
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
end)

h.test("<leader>uN adds the filename, and a second boot keeps it", function()
  h.with_state(nil, function()
    editing_changed_file()
    local text = wait_for_statusline(function(text)
      return contains(text, "2.9k")
    end)
    h.eq(false, contains(text, "tracked.txt"), "no filename by default\nstatusline: " .. text)

    -- Unmapped, the keys would leave which-key waiting for more.
    h.eq(true, vim.fn.maparg(vim.g.mapleader .. "uN", "n") ~= "", "<leader>uN is mapped")
    vim.api.nvim_feedkeys(vim.g.mapleader .. "uN", "mx", false)
    text = wait_for_statusline(function(text)
      return contains(text, "tracked.txt")
    end)
    h.eq(true, contains(text, "tracked.txt"), "filename after <leader>uN\nstatusline: " .. text)

    local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
    local cmd = { "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }
    local env = { TEST_SPEC = root .. "/tests/statusline/boot.lua", EXPECT_FILE = file }
    local result = vim.system(cmd, { env = env, text = true }):wait(60000)
    h.eq(0, result.code, "second instance:\n" .. (result.stdout or "") .. (result.stderr or ""))

    vim.api.nvim_feedkeys(vim.g.mapleader .. "uN", "mx", false)
    text = wait_for_statusline(function(text)
      return not contains(text, "tracked.txt")
    end)
    h.eq(false, contains(text, "tracked.txt"), "no filename after a second <leader>uN\nstatusline: " .. text)
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

--- The foreground of the mode icon `icon`, as the statusline draws it after
--- typing `keys`, as "#rrggbb". The screen doesn't give colours, and the mode
--- only lasts as long as the keys, so this draws lualine's statusline itself.
local function icon_colour(keys, icon)
  icon = vim.trim(icon)
  local colour
  _G.statusline_spec_capture = function()
    local drawn = vim.api.nvim_eval_statusline(require("lualine").statusline(true), { highlights = true })
    local at = assert(drawn.str:find(icon, 1, true), "no mode icon in: " .. drawn.str) - 1
    local group
    for _, hl in ipairs(drawn.highlights) do
      if hl.start <= at then
        group = hl.group
      end
    end
    local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    colour = fg and ("#%06x"):format(fg)
  end
  vim.api.nvim_feedkeys(vim.keycode(keys .. "<Cmd>lua statusline_spec_capture()<CR><Esc>"), "nx", false)
  _G.statusline_spec_capture = nil
  return colour
end

h.test("after switching theme, the mode icon's colour follows the new theme's Mode colours", function()
  h.with_state(nil, function()
    editing_changed_file()
    -- Each theme's insert and copy colours (see tint_spec). Copy shows while
    -- `y` waits for a motion, where lualine's own colour would be normal mode's.
    for theme, colours in pairs({
      ["tokyonight-moon"] = { insert = "#c3e88d", copy = "#ffc777" },
      ["catppuccin-mocha"] = { insert = "#a6e3a1", copy = "#f9e2af" },
    }) do
      h.apply_theme(theme)
      h.eq(colours.insert, icon_colour("i", icons.modes.insert), theme .. " insert-mode icon")
      h.eq(colours.copy, icon_colour("y", icons.modes.normal), theme .. " icon while copying")
    end
  end)
end)
