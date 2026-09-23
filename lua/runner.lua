-- Code runner (VS Code Code Runner parity). `:RunFile` saves the current file
-- and runs it with the command for its filetype, in one bottom split terminal
-- that each run reuses. Compiled binaries go to a temp file, never the project.
local M = {}

local q = vim.fn.shellescape

--- Run `file` with `interpreter`.
local function interpret(interpreter)
  return function(file)
    return interpreter .. " " .. q(file)
  end
end

--- Compile `file` with `compiler` to a temp binary, then run that binary.
local function compile_and_run(compiler, file)
  local out = q(vim.fn.tempname())
  return ("%s %s -o %s && %s"):format(compiler, q(file), out, out)
end

-- Per filetype, the shell command that runs `file`.
---@type table<string, fun(file: string): string>
local runners = {
  python = interpret("python3"),
  go = interpret("go run"),
  javascript = interpret("node"),
  typescript = interpret("deno run"),
  lua = interpret("nvim -l"),
  rust = function(file)
    local manifest = vim.fs.find("Cargo.toml", { path = vim.fs.dirname(file), upward = true })[1]
    if manifest then
      return "cargo run --manifest-path " .. q(manifest)
    end
    return compile_and_run("rustc", file)
  end,
  c = function(file)
    return compile_and_run("clang", file)
  end,
  cpp = function(file)
    return compile_and_run("clang++", file)
  end,
}

-- The terminal the last run went to, so the next run can reuse its window.
local term = { buf = nil, job = nil }

--- Run `cmd` in the runner's bottom split, replacing the previous run's
--- terminal in the same window. Focus stays where it was.
local function run_in_terminal(cmd)
  local from = vim.api.nvim_get_current_win()
  local win = term.buf and vim.fn.bufwinid(term.buf) or -1
  if win == -1 then
    vim.cmd("botright " .. math.floor(vim.o.lines * 0.3) .. "split")
    win = vim.api.nvim_get_current_win()
    vim.wo[win].winfixheight = true
  end
  if term.job then
    vim.fn.jobstop(term.job)
  end
  local old = term.buf
  term.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, term.buf)
  vim.api.nvim_win_call(win, function()
    term.job = vim.fn.jobstart(cmd, { term = true })
    -- A terminal window only follows new output while its cursor is on the last line.
    vim.cmd.normal({ "G", bang = true })
  end)
  if old and vim.api.nvim_buf_is_valid(old) then
    vim.api.nvim_buf_delete(old, { force = true })
  end
  vim.api.nvim_set_current_win(from)
end

--- The command that runs the current buffer's file, or nil and why not.
---@return string?, string?
local function resolve()
  local ft = vim.bo.filetype
  local runner = runners[ft]
  if not runner then
    return nil, "No runner for " .. (ft ~= "" and ft or "this buffer")
  end
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return nil, "Save the file before running it"
  end
  return runner(file)
end

--- Save the current file and run it. With `dry_run`, only return the command
--- that would run. Returns nil when there is nothing to run.
---@param opts? {dry_run?: boolean}
---@return string?
function M.run(opts)
  local cmd, why = resolve()
  if opts and opts.dry_run then
    return cmd
  end
  if not cmd then
    vim.notify(why, vim.log.levels.WARN)
    return nil
  end
  -- :update alone would skip a new file that was never written.
  local file = vim.api.nvim_buf_get_name(0)
  if vim.bo.modified or vim.fn.filereadable(file) == 0 then
    local ok, err = pcall(vim.cmd.write)
    if not ok then
      vim.notify("Not running: " .. err, vim.log.levels.ERROR)
      return nil
    end
  end
  run_in_terminal(cmd)
  return cmd
end

function M.setup()
  vim.api.nvim_create_user_command("RunFile", function()
    M.run()
  end, { desc = "Save and run the current file" })
end

return M
