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
    error(("%s\nexpected: %s\n  actual: %s"):format(what or "values differ", vim.inspect(expected), vim.inspect(actual)), 2)
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
  vim.wait(1000, function() return false end)

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
    vim.schedule(function() run(spec) end)
  end,
})

return M
