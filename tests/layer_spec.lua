local h = require("harness")
local icons = require("util.icons")

h.attach_ui(160, 30)

-- A git repo with a committed file, then edited in two places far apart, so
-- the file has two hunks and the cursor can start on neither.
local repo = vim.fn.tempname()
vim.fn.mkdir(repo, "p")
repo = assert(vim.uv.fs_realpath(repo))
local file = repo .. "/tracked.txt"
local lines = {}
for i = 1, 40 do
  lines[i] = "line " .. i
end
vim.fn.writefile(lines, file)
local function git(...)
  local result = vim.system({ "git", "-C", repo, ... }, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
git("init", "-b", "main")
git("add", ".")
git("-c", "user.name=test", "-c", "user.email=test@example.com", "commit", "-m", "init")
lines[10], lines[30] = "changed 10", "changed 30"
vim.fn.writefile(lines, file)
vim.fn.chdir(repo)

---@param keys string
local function press(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "mx", false)
end

local function wait_for(what, ok)
  h.eq(true, vim.wait(5000, ok, 20), what)
end

local function layer()
  return require("layer").active()
end

local function hunks()
  return require("gitsigns").get_hunks(0) or {}
end

--- Edit the file, with its two hunks (lines 10 and 30 changed), the cursor
--- on line 1, and gitsigns attached and caught up. Not reloaded when it's
--- already open: gitsigns detaches if the file reloads while it's refreshing
--- (as it does when a layer is left and the signs hide again).
local function editing_two_hunks()
  if layer() then
    layer():exit()
  end
  if vim.api.nvim_buf_get_name(0) ~= file then
    vim.cmd.edit(file)
  end
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  wait_for("gitsigns sees two hunks", function()
    return #hunks() == 2
  end)
end

local function cursor_line()
  return vim.api.nvim_win_get_cursor(0)[1]
end

--- Press <leader>gH and wait until the layer is on and gitsigns has caught up:
--- showing the signs makes it work the hunks out again, and a person can't
--- press the next key before it's done, but a test can.
local function entering_layer()
  press("<leader>gH")
  wait_for("in the layer", function()
    return layer() ~= nil
  end)
  wait_for("gitsigns caught up", function()
    return #hunks() == 2
  end)
end

h.test("<leader>gH enters the Git layer, on the first hunk", function()
  editing_two_hunks()
  press("<leader>gH")
  wait_for("the Git layer is active", function()
    return layer() ~= nil and layer().name == "Git"
  end)
  wait_for("the cursor is on the first hunk", function()
    return cursor_line() == 10
  end)
end)

h.test("n/j go to the next hunk and p/k to the previous one", function()
  editing_two_hunks()
  entering_layer()
  wait_for("on the first hunk", function()
    return cursor_line() == 10
  end)
  for _, step in ipairs({ { "n", 30 }, { "p", 10 }, { "j", 30 }, { "k", 10 } }) do
    press(step[1])
    wait_for(step[1] .. " moves to line " .. step[2], function()
      return cursor_line() == step[2]
    end)
  end
end)

h.test("j/k still move lines in visual mode", function()
  editing_two_hunks()
  press("<leader>gH")
  wait_for("on the first hunk", function()
    return cursor_line() == 10
  end)
  local selected
  _G.layers_spec_capture = function()
    selected = { vim.fn.line("v"), vim.fn.line(".") }
  end
  press("Vjj<Cmd>lua layers_spec_capture()<CR><Esc>")
  _G.layers_spec_capture = nil
  h.eq({ 10, 12 }, selected, "V j j selects three lines")
end)

h.test("s stages the hunk under the cursor", function()
  editing_two_hunks()
  press("<leader>gH")
  wait_for("on the first hunk", function()
    return cursor_line() == 10
  end)
  press("s")
  local staged = vim.wait(5000, function()
    return #hunks() == 1
  end, 20)
  git("reset", "-q") -- unstaged again for the tests after
  h.eq(true, staged, "one unstaged hunk left")
end)

h.test("the gutter shows git signs only while the layer is active", function()
  editing_two_hunks()
  local config = require("gitsigns.config").config
  h.eq(false, config.signcolumn, "signs hidden before")
  press("<leader>gH")
  wait_for("signs shown in the layer", function()
    return config.signcolumn == true
  end)
  press("q")
  wait_for("signs hidden again", function()
    return config.signcolumn == false
  end)
end)

h.test("q and <esc> leave the layer and give back the keys it covered", function()
  for _, exit in ipairs({ "q", "<esc>" }) do
    editing_two_hunks()
    local before = vim.fn.maparg("s", "n", false, true)
    press("<leader>gH")
    wait_for("in the layer", function()
      return layer() ~= nil
    end)
    press(exit)
    h.eq(nil, layer(), exit .. " leaves the layer")
    h.eq(before, vim.fn.maparg("s", "n", false, true), exit .. " restores s")
  end
end)

h.test("d opens the diff and stays in the layer", function()
  editing_two_hunks()
  local win = vim.api.nvim_get_current_win()
  entering_layer()
  press("d")
  wait_for("a diff split", function()
    return #vim.api.nvim_tabpage_list_wins(0) > 1 and vim.wo[win].diff
  end)
  h.eq(true, layer() ~= nil, "still in the layer")
  h.eq(win, vim.api.nvim_get_current_win(), "back in the file's window")
  press("q")
  vim.cmd.only({ bang = true })
  vim.cmd.diffoff({ bang = true })
end)

h.test("q still leaves after the help was closed another way", function()
  editing_two_hunks()
  press("<leader>gH")
  wait_for("in the layer", function()
    return layer() ~= nil
  end)
  local before = vim.api.nvim_list_wins()
  press("?")
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if not vim.list_contains(before, win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  press("q")
  h.eq(nil, layer(), "left the layer")
  h.eq(false, vim.fn.maparg("q", "n") ~= "" and vim.fn.maparg("q", "n", false, true).desc == "leave", "q given back")
end)

h.test("switching to another file leaves the layer", function()
  editing_two_hunks()
  press("<leader>gH")
  wait_for("in the layer", function()
    return layer() ~= nil
  end)
  vim.cmd.enew()
  h.eq(nil, layer(), "left with the buffer")
end)

h.test("<leader>gH doesn't enter in a buffer git doesn't track", function()
  editing_two_hunks()
  vim.cmd.enew()
  press("<leader>gH")
  vim.wait(200, function()
    return false
  end)
  h.eq(nil, layer(), "no layer in a scratch buffer")
end)

h.test("? shows and hides a help window styled like the other floats", function()
  editing_two_hunks()
  press("<leader>gH")
  wait_for("in the layer", function()
    return layer() ~= nil
  end)
  -- The float listing the layer's keys (not, say, a notification's).
  local function help_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), "\n")
      if config.relative ~= "" and text:find("stage hunk", 1, true) then
        return win, config
      end
    end
  end
  h.eq(nil, help_win(), "no help until ?")
  press("?")
  local win, config = help_win()
  h.eq(true, win ~= nil, "? shows the help")
  local title = vim
    .iter(config.title)
    :map(function(chunk)
      return chunk[1]
    end)
    :join("")
  h.eq(true, title:find("Git", 1, true) ~= nil, "titled Git: " .. title)
  h.eq(true, vim.wo[win].winhighlight:find("Normal:NormalFloat", 1, true) ~= nil, "uses NormalFloat")
  press("?")
  h.eq(nil, help_win(), "? hides it again")
  press("?")
  press("q")
  h.eq(nil, help_win(), "leaving the layer closes the help")
end)

h.test("the statusline's mode icon becomes the layer's, in the gutter's change colour", function()
  editing_two_hunks()
  press("<leader>gH")
  wait_for("in the layer", function()
    return layer() ~= nil
  end)
  local result = vim.api.nvim_eval_statusline(require("lualine").statusline(true), { highlights = true })
  local branch = vim.trim(icons.git.Branch)
  local at = result.str:find(branch, 1, true)
  h.eq(true, at ~= nil, "branch icon in: " .. result.str)
  local group
  for _, hl in ipairs(result.highlights) do
    if hl.start <= at - 1 then
      group = hl.group
    end
  end
  local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
  h.eq(Snacks.util.color("GitSignsChange"), fg and ("#%06x"):format(fg), "drawn in GitSignsChange")
  press("q")
end)

h.test("no errors", function()
  -- gitsigns opens folds at each hunk it jumps to with `silent! foldopen!`,
  -- which still leaves E490 in v:errmsg when there's no fold.
  local errors = vim.tbl_filter(function(err)
    return not err:find("E490: No fold found", 1, true)
  end, h.errors())
  h.eq({}, errors, "errors")
end)
