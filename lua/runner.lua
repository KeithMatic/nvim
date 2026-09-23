-- Code runner (VS Code Code Runner parity). `:RunFile` saves the current file
-- and runs it with the command for its filetype, in one bottom split terminal
-- that each run reuses. LazyVim has no runner extra, so this module holds only
-- the filetype → command table; the terminal is Snacks'. Compiled binaries go
-- to a temp file, never the project.
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

-- The last run's terminal (a Snacks terminal, which LazyVim ships).
---@type snacks.win?
local term

--- Run `cmd` in a bottom split terminal that replaces the previous run's,
--- stopping it if it's still going. Focus stays where it was.
local function run_in_terminal(cmd)
  if term then
    term:close() -- also deletes the buffer, which stops its job
  end
  term = Snacks.terminal.open(cmd, {
    -- Not interactive: no insert mode, and the output stays after the program exits.
    interactive = false,
    win = { position = "bottom", height = 0.3, enter = false },
  })
  -- A terminal window only follows new output while its cursor is on the last line.
  vim.api.nvim_win_call(term.win, function()
    vim.cmd.normal({ "G", bang = true })
  end)
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
