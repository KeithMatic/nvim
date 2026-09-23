local h = require("harness")

local leader = vim.g.mapleader

-- A project to explore, with the file nested so revealing it has to open folders.
local project = vim.fn.tempname()
vim.fn.mkdir(project .. "/src/deep", "p")
project = assert(vim.uv.fs_realpath(project)) -- as neo-tree shows it (macOS: /var is /private/var)
local file = project .. "/src/deep/target.txt"
vim.fn.writefile({ "hello" }, file)
vim.fn.writefile({}, project .. "/README.md")
vim.fn.chdir(project)

--- The Explorer's window in this tab, if it's open.
local function explorer_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      return win
    end
  end
end

--- Wait for the Explorer's cursor to land on `name` (it renders asynchronously).
local function wait_for_selected(name)
  vim.wait(5000, function()
    local win = explorer_win()
    return win and vim.api.nvim_get_current_line():find(name, 1, true) ~= nil
  end, 50)
  return vim.api.nvim_get_current_line()
end

local function press(keys)
  vim.api.nvim_feedkeys(keys, "mx", false)
end

--- Close any open Explorer and start editing the file.
local function editing_file()
  pcall(vim.cmd, "Neotree close")
  vim.cmd.edit(file)
end

--- Whether a window's border draws nothing.
local function borderless(win)
  local border = vim.api.nvim_win_get_config(win).border
  if border == nil or border == "none" then
    return true
  end
  return type(border) == "table"
    and vim.iter(border):all(function(part)
      return (type(part) == "table" and part[1] or part) == ""
    end)
end

h.test("<leader>e and <leader>E open the Explorer, not the Snacks explorer", function()
  editing_file()
  press(leader .. "e")
  local opened = vim.wait(5000, function()
    return explorer_win() ~= nil
  end, 50)
  h.eq(true, opened, "the Explorer opened")
  h.eq(0, #Snacks.picker.get({ source = "explorer" }), "Snacks explorers open")
  vim.cmd("Neotree close")
  h.eq(false, vim.fn.maparg(leader .. "E", "n") == "", "<leader>E is mapped")
end)

h.test("float: <leader>o opens a centred, borderless float on the current file", function()
  editing_file()
  press(leader .. "o")
  local line = wait_for_selected("target.txt")
  local win = explorer_win()
  h.eq(true, win ~= nil, "the Explorer opened")
  h.eq(win, vim.api.nvim_get_current_win(), "the Explorer has focus")
  h.eq(true, line:find("target.txt", 1, true) ~= nil, "the selected line: " .. line)

  local config = vim.api.nvim_win_get_config(win)
  h.eq("editor", config.relative, "floating over the editor")
  h.eq(true, borderless(win), "border: " .. vim.inspect(config.border))
  local pos = vim.api.nvim_win_get_position(win)
  local left, right = pos[2], vim.o.columns - pos[2] - config.width
  local top, bottom = pos[1], vim.o.lines - pos[1] - config.height
  h.eq(true, math.abs(left - right) <= 1, ("columns either side: %d, %d"):format(left, right))
  h.eq(true, math.abs(top - bottom) <= 2, ("rows above and below: %d, %d"):format(top, bottom))
end)

h.test("float: <leader>o again closes it", function()
  editing_file()
  press(leader .. "o")
  wait_for_selected("target.txt")
  press(leader .. "o")
  local closed = vim.wait(2000, function()
    return explorer_win() == nil
  end, 50)
  h.eq(true, closed, "the Explorer closed")
  h.eq(file, vim.api.nvim_buf_get_name(0), "back in the file")
end)

--- The Explorer's tab bar as drawn: its text, its highlight segments (each
--- with its text and group) and the window's width.
local function tab_bar()
  editing_file()
  press(leader .. "o")
  wait_for_selected("target.txt")
  local win = assert(explorer_win(), "the Explorer opened")
  local bar = vim.api.nvim_eval_statusline(vim.wo[win].winbar, { winid = win, use_winbar = true, highlights = true })
  local width = vim.api.nvim_win_get_width(win)
  vim.cmd("Neotree close")
  local segments = {}
  for i, hl in ipairs(bar.highlights) do
    local next_start = bar.highlights[i + 1] and bar.highlights[i + 1].start or #bar.str
    table.insert(segments, { text = bar.str:sub(hl.start + 1, next_start), group = hl.group })
  end
  return { str = bar.str, segments = segments, width = width }
end

h.test("the only tab is Files, its label centred", function()
  local bar = tab_bar()
  h.eq({ "Files" }, vim.iter(bar.str:gmatch("%a+")):totable(), "tab labels in: " .. bar.str)
  local before, after = #bar.str:match("^ *"), #bar.str:match(" *$")
  h.eq(
    true,
    math.abs(before - after) <= 1,
    ("%d spaces before the label, %d after in: %q"):format(before, after, bar.str)
  )
end)

h.test("the tree starts right under the tab, at the root folder", function()
  editing_file()
  h.eq(true, h.focus_explorer(), "the Explorer has focus")
  local first = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
  vim.cmd("Neotree close")
  -- The root is shown as its path, cut off at the window's width.
  h.eq(true, first:find(project:sub(1, 15), 1, true) ~= nil, "the root folder first: " .. first)
end)

h.test("there is no border around the tab", function()
  local bar = tab_bar()
  local icons = require("util.icons")
  local drawn = bar.str:gsub(vim.pesc(vim.trim(icons.ui.Files)), "")
  h.eq("", (drawn:gsub("[%a ]", "")), "anything but the label and spaces in: " .. bar.str)
end)

h.test("the Git view still opens with <leader>ge", function()
  editing_file()
  press(leader .. "ge")
  local opened = vim.wait(5000, function()
    local win = explorer_win()
    return win ~= nil and vim.b[vim.api.nvim_win_get_buf(win)].neo_tree_source == "git_status"
  end, 50)
  pcall(vim.cmd, "Neotree close")
  h.eq(true, opened, "the Git view opened")
end)

h.test("the tab bar has no underline, in every theme", function()
  for _, theme in ipairs({ "tokyonight-moon", "catppuccin-mocha" }) do
    h.apply_theme(theme)
    for _, segment in ipairs(tab_bar().segments) do
      local hl = vim.api.nvim_get_hl(0, { name = segment.group, link = false })
      local what = ("%s: %q (%s)"):format(theme, segment.text, segment.group)
      h.eq({}, { hl.underline, hl.underdashed }, what .. " has no underline")
    end
  end
end)

h.test("docked: <leader>o switches focus between the Explorer and the file", function()
  -- Dock it on the left, as changing the Explorer position setting would.
  pcall(vim.cmd, "Neotree close")
  require("neo-tree").setup(
    vim.tbl_deep_extend("force", LazyVim.opts("neo-tree.nvim"), { window = { position = "left" } })
  )
  editing_file()
  local editor = vim.api.nvim_get_current_win()

  press(leader .. "o")
  local line = wait_for_selected("target.txt")
  local win = explorer_win()
  h.eq(true, win ~= nil and win == vim.api.nvim_get_current_win(), "the Explorer has focus")
  h.eq("", vim.api.nvim_win_get_config(win).relative, "docked, not floating")
  h.eq(0, vim.api.nvim_win_get_position(win)[2], "on the left")
  h.eq(true, line:find("target.txt", 1, true) ~= nil, "the selected line: " .. line)

  press(leader .. "o")
  h.eq(editor, vim.api.nvim_get_current_win(), "back in the file's window")
  h.eq(true, explorer_win() ~= nil, "the Explorer stays open")

  press(leader .. "o")
  h.eq(win, vim.api.nvim_get_current_win(), "the Explorer again")
  vim.cmd("Neotree close")
end)
