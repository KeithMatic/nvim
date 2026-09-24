local h = require("harness")

local state = require("toggle_state")
local state_file = vim.fn.stdpath("state") .. "/toggle-state.json"

local function with_state(content, fn)
  local before = vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file, "b") or nil
  if content then
    vim.fn.mkdir(vim.fs.dirname(state_file), "p")
    vim.fn.writefile(vim.split(content, "\n"), state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  state.reload()
  local ok, err = pcall(fn)
  if before then
    vim.fn.writefile(before, state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  state.reload()
  if not ok then
    error(err, 0)
  end
end

h.test("missing and malformed toggle state use defaults", function()
  with_state(nil, function()
    h.eq(true, state.get("ui.dropbar", true))
  end)
  with_state("{not json", function()
    h.eq(false, state.get("ui.dropbar", false))
  end)
  with_state('{"version":1,"toggles":{"ui.dropbar":"yes"}}', function()
    h.eq(true, state.get("ui.dropbar", true))
  end)
end)

h.test("set saves values and preserves unknown keys", function()
  with_state('{"version":1,"toggles":{"future.toggle":true}}', function()
    state.set("ui.dropbar", false)
    local saved = vim.json.decode(table.concat(vim.fn.readfile(state_file), "\n"))
    h.eq(1, saved.version)
    h.eq({ ["future.toggle"] = true, ["ui.dropbar"] = false }, saved.toggles)
  end)
end)

h.test("registered setters save only after the underlying change succeeds", function()
  with_state(nil, function()
    local applied
    local set = state.setter("ui.example", function(value)
      applied = value
    end)
    set(true)
    h.eq(true, applied)
    h.eq(true, state.get("ui.example", false))

    local failing = state.setter("ui.failed", function()
      error("cannot apply")
    end)
    local ok = pcall(failing, true)
    h.eq(false, ok)
    h.eq(false, state.get("ui.failed", false))
  end)
end)

h.test(":ToggleStateReset deletes only toggle state", function()
  with_state(nil, function()
    local theme_file = vim.fn.stdpath("state") .. "/theme.json"
    local theme_before = vim.fn.filereadable(theme_file) == 1 and vim.fn.readfile(theme_file, "b") or nil
    vim.fn.writefile({ '{"theme":"tokyonight-moon"}' }, theme_file)
    state.set("ui.dropbar", false)
    vim.cmd.ToggleStateReset()
    h.eq(0, vim.fn.filereadable(state_file), "toggle state removed")
    h.eq(1, vim.fn.filereadable(theme_file), "theme state kept")
    if theme_before then
      vim.fn.writefile(theme_before, theme_file, "b")
    else
      vim.fn.delete(theme_file)
    end
  end)
end)
