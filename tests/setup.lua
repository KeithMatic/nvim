-- Sandbox setup, run by run.sh after `Lazy! restore` with a Lua file open (so
-- LSP config loads too). Lets LazyVim install its Mason tools and Treesitter
-- parsers, and waits for them, so test boots don't start (and kill) installs.
vim.api.nvim_exec_autocmds("UIEnter", {}) -- fire VeryLazy; headless has no UI

local function missing()
  local todo = {}
  local ok_ts, TS = pcall(require, "nvim-treesitter")
  if ok_ts and TS.get_installed then
    local have = TS.get_installed()
    for _, lang in ipairs(LazyVim.opts("nvim-treesitter").ensure_installed or {}) do
      if not vim.list_contains(have, lang) then
        table.insert(todo, "parser " .. lang)
      end
    end
  end
  local ok_mr, registry = pcall(require, "mason-registry")
  if ok_mr then
    for _, pkg in ipairs(registry.get_all_packages()) do
      if pkg:is_installing() then
        table.insert(todo, "mason " .. pkg.name .. " (installing)")
      end
    end
    for _, name in ipairs(LazyVim.opts("mason.nvim").ensure_installed or {}) do
      if not registry.is_installed(name) then
        table.insert(todo, "mason " .. name)
      end
    end
  end
  return todo
end

-- Installs are queued asynchronously, so only trust "nothing missing" once it has held for a few seconds.
local idle_since
local done = vim.wait(10 * 60 * 1000, function()
  if #missing() > 0 then
    idle_since = nil
    return false
  end
  idle_since = idle_since or vim.uv.now()
  return vim.uv.now() - idle_since > 3000
end, 200)

if not done then
  io.stdout:write("Sandbox setup timed out waiting for: " .. table.concat(missing(), ", ") .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qall!")
