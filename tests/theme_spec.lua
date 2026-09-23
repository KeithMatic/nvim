local h = require("harness")

local curated = {
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha",
  "tokyonight-moon",
  "tokyonight-night",
  "tokyonight-storm",
}

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- Boot a second headless Neovim on this config and assert that it starts with
--- `theme` and no errors. It shares this instance's sandbox, so it reads the
--- state this instance saved.
local function assert_boots_with(theme)
  local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
  local cmd = { "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }
  local env = { TEST_SPEC = root .. "/tests/theme/boot.lua", EXPECT_THEME = theme }
  local result = vim.system(cmd, { env = env, text = true }):wait(60000)
  h.eq(0, result.code, "second instance:\n" .. (result.stdout or "") .. (result.stderr or ""))
end

--- Run `fn` with the saved state set to `content` (nil: no state file), then
--- put back whatever was saved before, so other specs boot as they would have.
local function with_state(content, fn)
  local saved = vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file, "b") or nil
  if content then
    vim.fn.writefile(vim.split(content, "\n"), state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  local ok, err = pcall(fn)
  if saved then
    vim.fn.writefile(saved, state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  if not ok then
    error(err, 0)
  end
end

--- Open the <leader>uC picker and return it once it has its items.
local function open_picker()
  vim.api.nvim_feedkeys(vim.g.mapleader .. "uC", "mx", false)
  local picker
  vim.wait(5000, function()
    picker = Snacks.picker.get({ source = "colorschemes" })[1]
    return picker ~= nil and not picker:is_active()
  end, 50)
  return assert(picker, "<leader>uC opened no colorscheme picker")
end

--- Cancel `picker` (what its <Esc> does) and wait until the theme is back to `theme`.
local function cancel(picker, theme)
  picker:close()
  vim.wait(2000, function()
    return picker.closed and vim.g.colors_name == theme
  end, 50)
end

h.test("<leader>uC lists exactly the six curated dark themes", function()
  with_state(nil, function()
    local before = vim.g.colors_name
    local picker = open_picker()
    local names = vim.tbl_map(function(item)
      return item.text
    end, picker:items())
    cancel(picker, before)
    table.sort(names)
    h.eq(curated, names)
  end)
end)

h.test("the picker previews themes live, and cancelling restores and saves nothing new", function()
  with_state(nil, function()
    vim.cmd.colorscheme("tokyonight-night")
    local picker = open_picker()
    -- Move off the current theme, then see the one under the cursor applied.
    local target, shown, saved
    for _ = 1, #curated do
      target = picker:current().text
      if target ~= "tokyonight-night" then
        break
      end
      vim.api.nvim_feedkeys(vim.keycode("<Down>"), "x", false)
    end
    vim.wait(2000, function()
      return vim.g.colors_name == target
    end, 50)
    shown = vim.g.colors_name
    saved = vim.json.decode(vim.fn.readfile(state_file)[1]).theme
    cancel(picker, "tokyonight-night")

    h.eq(target, shown, "the theme under the cursor is applied")
    h.eq("tokyonight-night", saved, "a preview isn't saved")
    h.eq("tokyonight-night", vim.g.colors_name, "cancel restores the theme")
    assert_boots_with("tokyonight-night")
  end)
end)

h.test("a theme chosen in the picker is restored on the next start", function()
  with_state(nil, function()
    vim.cmd.colorscheme("tokyonight-night")
    local picker = open_picker()
    -- The picker's input is in normal mode here: j moves down, <CR> confirms.
    for _ = 1, #curated do
      if picker:current().text == "catppuccin-mocha" then
        break
      end
      vim.api.nvim_feedkeys("j", "x", false)
    end
    vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
    vim.wait(2000, function()
      return picker.closed and vim.g.colors_name == "catppuccin-mocha"
    end, 50)
    h.eq("catppuccin-mocha", vim.g.colors_name, "applied")
    assert_boots_with("catppuccin-mocha")
  end)
end)

h.test("a theme applied with :colorscheme is restored on the next start", function()
  with_state(nil, function()
    vim.cmd.colorscheme("catppuccin-frappe")
    assert_boots_with("catppuccin-frappe")
    vim.cmd.colorscheme("tokyonight-storm")
    assert_boots_with("tokyonight-storm")
  end)
end)

h.test("with no saved theme, startup uses tokyonight-moon", function()
  with_state(nil, function()
    assert_boots_with("tokyonight-moon")
  end)
end)

h.test("an unknown saved theme falls back to tokyonight-moon without errors", function()
  with_state('{"theme":"no-such-theme"}', function()
    assert_boots_with("tokyonight-moon")
  end)
end)

h.test("a corrupt state file falls back to tokyonight-moon without errors", function()
  with_state("{not json", function()
    assert_boots_with("tokyonight-moon")
  end)
end)

h.test("the saved state lives in Neovim's state directory", function()
  with_state(nil, function()
    vim.cmd.colorscheme("catppuccin-mocha")
    h.eq(1, vim.fn.filereadable(state_file), state_file .. " written")
  end)
end)
