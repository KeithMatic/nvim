-- Test harness: loaded with `--cmd` before the config so it can capture startup
-- errors, then runs one spec file once the config has fully booted.
-- Specs `require("harness")` and register tests with `h.test(name, fn)`.
local M = {}

local tests = {}
local notified_errors = {}

-- Record error notifications sent before any notifier plugin takes over.
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if (level or vim.log.levels.INFO) >= vim.log.levels.ERROR then
    table.insert(notified_errors, tostring(msg))
  end
  return orig_notify(msg, level, opts)
end

---@param name string
---@param fn fun()
function M.test(name, fn)
  table.insert(tests, { name = name, fn = fn })
end

function M.eq(expected, actual, what)
  if not vim.deep_equal(expected, actual) then
    error(
      ("%s\nexpected: %s\n  actual: %s"):format(what or "values differ", vim.inspect(expected), vim.inspect(actual)),
      2
    )
  end
end

--- Apply `theme` and let the scheduled transparency pass run.
---@param theme string
function M.apply_theme(theme)
  vim.cmd.colorscheme(theme)
  vim.wait(200, function()
    return false
  end)
end

--- Focus the Explorer and wait until it has drawn its tree: closed before then,
--- its pending first render opens it again.
---@return boolean focused
function M.focus_explorer()
  vim.cmd("Neotree focus")
  return vim.wait(5000, function()
    return vim.bo.filetype == "neo-tree" and vim.api.nvim_get_current_line() ~= ""
  end, 50)
end

---@param keys string
---@param mode string
function M.feed(keys, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), mode, false)
end

--- Enter insert or cmdline mode with `keys` and stay there while `steps` run
--- one after another from a timer, so asynchronous things (the completion
--- menu, noice's popup) can happen. A string step is typed; a function step is
--- polled until it returns something other than false. The mode is left with
--- <Esc> once every step is done.
---@param keys string
---@param steps (string|fun(): any)[]
function M.drive(keys, steps)
  local i, err = 1, nil
  local deadline = vim.uv.now() + 5000
  local timer = assert(vim.uv.new_timer())
  local function stop()
    timer:stop()
    timer:close()
  end
  local function finish()
    stop()
    M.feed("<Esc>", "t")
  end
  timer:start(
    50,
    50,
    vim.schedule_wrap(function()
      if timer:is_closing() then
        return
      end
      local step = steps[i]
      if step == nil then
        return finish()
      elseif type(step) == "string" then
        M.feed(step, "t")
        i = i + 1
      else
        local ok, ret = pcall(step)
        if not ok or vim.uv.now() > deadline then
          err = ok and ("step %d timed out"):format(i) or ret
          return finish()
        elseif ret ~= false then
          i = i + 1
        end
      end
    end)
  )
  M.feed(keys, "x!")
  if not timer:is_closing() then -- the mode ended early (e.g. into select mode)
    stop()
    err = err or ("mode ended before step %d"):format(i)
  end
  if err then
    error(err, 2)
  end
end

--- Attach Neovim's own TUI, `width` by `height`, from a child process. Headless
--- Neovim has no UI, so it never redraws, and plugins that draw through
--- vim.ui_attach (noice's cmdline) get no events until a UI is attached.
---@param width integer
---@param height integer
function M.attach_ui(width, height)
  vim.fn.jobstart({ "nvim", "--server", vim.v.servername, "--remote-ui" }, {
    pty = true,
    width = width,
    height = height,
    env = { NVIM = "" }, -- else the child refuses to attach to its "parent"
  })
  local attached = vim.wait(5000, function()
    return vim.o.columns == width and vim.o.lines == height
  end, 20)
  M.eq(true, attached, ("a %dx%d UI attached (screen is %dx%d)"):format(width, height, vim.o.columns, vim.o.lines))
end

--- The statusline as the attached UI (see `attach_ui`) shows it: the screen's
--- last row above the cmdline.
---@return string
function M.statusline()
  vim.cmd.redraw()
  local row = vim.o.lines - vim.o.cmdheight
  local cells = {}
  for col = 1, vim.o.columns do
    table.insert(cells, vim.fn.screenstring(row, col))
  end
  return table.concat(cells)
end

local state_file = vim.fn.stdpath("state") .. "/theme.json"
local toggle_state_file = vim.fn.stdpath("state") .. "/toggle-state.json"

--- Run `fn` with the theme module's saved state set to `content` (nil: no
--- state file), then put back whatever was saved before, so other specs boot
--- as they would have.
---@param content string?
---@param fn fun()
function M.with_state(content, fn)
  local before = vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file, "b") or nil
  local toggles_before = vim.fn.filereadable(toggle_state_file) == 1 and vim.fn.readfile(toggle_state_file, "b") or nil
  if content then
    vim.fn.writefile(vim.split(content, "\n"), state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  vim.fn.delete(toggle_state_file)
  if package.loaded.toggle_state then
    require("toggle_state").reload()
  end
  local ok, err = pcall(fn)
  if before then
    vim.fn.writefile(before, state_file, "b")
  else
    vim.fn.delete(state_file)
  end
  if toggles_before then
    vim.fn.writefile(toggles_before, toggle_state_file, "b")
  else
    vim.fn.delete(toggle_state_file)
  end
  if package.loaded.toggle_state then
    require("toggle_state").reload()
  end
  if not ok then
    error(err, 0)
  end
end

--- Every error the user would have seen: error notifications (early ones, and
--- the notifier's history), error messages, and the last `v:errmsg`.
---@return string[]
function M.errors()
  local errors = vim.deepcopy(notified_errors)
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.notifier and snacks.notifier.get_history then
    for _, notif in ipairs(snacks.notifier.get_history()) do
      if notif.level == "error" then
        table.insert(errors, notif.msg)
      end
    end
  end
  for _, line in ipairs(vim.split(vim.api.nvim_exec2("messages", { output = true }).output, "\n")) do
    if line:match("^E%d+:") or line:match("^Error") then
      table.insert(errors, line)
    end
  end
  if vim.v.errmsg ~= "" then
    table.insert(errors, "v:errmsg: " .. vim.v.errmsg)
  end
  return errors
end

local function out(s)
  io.stdout:write(s .. "\n")
end

local function run(spec)
  -- Headless Neovim has no UI, so lazy.nvim's VeryLazy (fired on UIEnter) would never run.
  vim.api.nvim_exec_autocmds("UIEnter", {})
  -- Let deferred startup work (VeryLazy plugins, replayed notifications) settle.
  vim.wait(1000, function()
    return false
  end)

  local ok, err = pcall(dofile, spec)
  if not ok then
    out("ERROR loading " .. spec .. ": " .. tostring(err))
    return vim.cmd("cquit 1")
  end

  local failed = 0
  for _, t in ipairs(tests) do
    local passed, msg = xpcall(t.fn, debug.traceback)
    if passed then
      out("  ok   " .. t.name)
    else
      failed = failed + 1
      out("  FAIL " .. t.name .. "\n" .. msg:gsub("\n", "\n       "))
    end
  end
  vim.cmd("cquit " .. failed)
end

local spec = assert(vim.env.TEST_SPEC, "TEST_SPEC not set")
package.path = vim.fs.dirname(spec) .. "/?.lua;" .. package.path
package.loaded.harness = M
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      run(spec)
    end)
  end,
})

return M
