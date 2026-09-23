local h = require("harness")

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

-- A plain project of single-file fixtures, a Cargo project, and a loose .rs file.
-- Resolved, as buffer names are (on macOS the temp dir is under a /var symlink).
local project = vim.fn.tempname()
vim.fn.mkdir(project, "p")
project = vim.fn.resolve(project)
write(project .. "/Cargo/Cargo.toml", { "[package]", 'name = "scratch"', 'version = "0.1.0"', 'edition = "2021"' })
write(project .. "/Cargo/src/main.rs", { "fn main() {}" })

--- Open `file` (relative to the project; created if missing) and return its path.
local function open(file, lines)
  local path = project .. "/" .. file
  if vim.fn.filereadable(path) == 0 then
    write(path, lines or {})
  end
  vim.cmd.edit({ vim.fn.fnameescape(path), bang = true })
  return path
end

--- The command `:RunFile` would run for `file`, without running it.
local function dry_run(file)
  open(file)
  return require("runner").run({ dry_run = true })
end

local q = vim.fn.shellescape

local interpreted = {
  { file = "main.py", ft = "python", cmd = "python3 %s" },
  { file = "main.go", ft = "go", cmd = "go run %s" },
  { file = "main.js", ft = "javascript", cmd = "node %s" },
  { file = "main.ts", ft = "typescript", cmd = "deno run %s" },
  { file = "main.lua", ft = "lua", cmd = "nvim -l %s" },
}
for _, case in ipairs(interpreted) do
  h.test(("dry run: %s runs with %s"):format(case.ft, case.cmd:format("<file>")), function()
    h.eq(case.cmd:format(q(project .. "/" .. case.file)), dry_run(case.file))
  end)
end

--- Assert `cmd` compiles `src` with `compiler` to a binary outside the project, then runs it.
local function assert_compiles(cmd, compiler, src)
  local prefix = compiler .. " " .. q(src) .. " -o "
  h.eq(prefix, cmd:sub(1, #prefix), "compiles " .. src .. ": " .. cmd)
  local out, ran = cmd:sub(#prefix + 1):match("^(.-) && (.*)$")
  h.eq(out, ran, "runs the binary it compiled: " .. cmd)
  -- Unquoted, with its (existing) directory resolved like the project's.
  local binary = out and vim.fn.resolve(vim.fs.dirname(out:sub(2, -2))) .. "/" .. vim.fs.basename(out:sub(2, -2))
  h.eq(true, binary ~= nil and not vim.startswith(binary, project .. "/"), "binary outside the project: " .. cmd)
end

h.test("dry run: c compiles with clang to a temp binary, then runs it", function()
  assert_compiles(dry_run("main.c"), "clang", project .. "/main.c")
end)

h.test("dry run: cpp compiles with clang++ to a temp binary, then runs it", function()
  assert_compiles(dry_run("main.cpp"), "clang++", project .. "/main.cpp")
end)

h.test("dry run: rust inside a Cargo project runs with cargo run", function()
  h.eq("cargo run --manifest-path " .. q(project .. "/Cargo/Cargo.toml"), dry_run("Cargo/src/main.rs"))
end)

h.test("dry run: a standalone .rs compiles with rustc to a temp binary, then runs it", function()
  assert_compiles(dry_run("loose.rs"), "rustc", project .. "/loose.rs")
end)

--- Terminal buffers shown in a window.
local function terminal_windows()
  return vim.tbl_filter(function(win)
    return vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal"
  end, vim.api.nvim_list_wins())
end

--- Assert that the terminal in `win` shows `want` on some line within 5s.
local function terminal_shows(win, want)
  local lines
  local found = vim.wait(5000, function()
    lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
    return vim.iter(lines):any(function(l)
      return l:find(want, 1, true) ~= nil
    end)
  end, 50)
  h.eq(true, found, ("terminal shows %q: %s"):format(want, vim.inspect(lines)))
end

h.test(":RunFile saves the buffer, then shows its output in a bottom split terminal", function()
  vim.cmd.only()
  local path = open("hello.lua", { 'print("first")' })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'print("second")' })
  local code_win = vim.api.nvim_get_current_win()
  vim.cmd.RunFile()

  h.eq({ 'print("second")' }, vim.fn.readfile(path), "saved before running")
  local wins = terminal_windows()
  h.eq(1, #wins, "one terminal window")
  terminal_shows(wins[1], "second")
  h.eq(vim.o.columns, vim.api.nvim_win_get_width(wins[1]), "full-width split")
  local below = vim.api.nvim_win_call(wins[1], function()
    return vim.fn.winnr("j")
  end)
  h.eq(vim.fn.win_id2win(wins[1]), below, "nothing below the terminal")
  h.eq(code_win, vim.api.nvim_get_current_win(), "focus stays in the code")
end)

h.test("running again reuses the one terminal split", function()
  vim.cmd.only()
  open("again.lua", { 'print("second")' })
  vim.cmd.RunFile()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'print("third")' })
  vim.cmd.RunFile()

  local wins = terminal_windows()
  h.eq(1, #wins, "still one terminal window")
  terminal_shows(wins[1], "third")
  local terminals = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal"
  end, vim.api.nvim_list_bufs())
  h.eq(1, #terminals, "no leftover terminal buffers")
end)

h.test("an unsupported filetype reports no runner and runs nothing", function()
  vim.cmd.only()
  open("notes.md")
  local messages = {}
  local notify = vim.notify
  vim.notify = function(msg)
    table.insert(messages, msg)
  end
  local ok, err = pcall(vim.cmd.RunFile)
  vim.notify = notify
  h.eq(true, ok, tostring(err))
  h.eq({ "No runner for markdown" }, messages)
  h.eq({}, terminal_windows(), "no terminal opened")
  h.eq(nil, require("runner").run({ dry_run = true }), "dry run resolves nothing")
end)

h.test(":RunFile writes a new file that was never saved", function()
  vim.cmd.only()
  local path = project .. "/new.lua"
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.cmd.RunFile()
  h.eq(1, vim.fn.filereadable(path), "written before running")
end)

h.test("<leader>cx runs the file, and is LazyVim's only <leader>cx mapping", function()
  local lhs = vim.g.mapleader .. "cx"
  local maps = vim.tbl_filter(function(m)
    return vim.startswith(m.lhs, lhs)
  end, vim.api.nvim_get_keymap("n"))
  h.eq(1, #maps, "one global normal mapping under <leader>cx: " .. vim.inspect(maps))
  h.eq("Run File", maps[1].desc, "which-key description")

  vim.cmd.only()
  open("keyed.lua", { 'print("keyed")' })
  vim.api.nvim_feedkeys(lhs, "mx", false)
  local wins = terminal_windows()
  h.eq(1, #wins, "one terminal window")
  terminal_shows(wins[1], "keyed")
end)
