-- Sandbox setup, run by run.sh after `Lazy! restore` with a Lua file open (so
-- LSP config loads too). Lets LazyVim install its Mason tools and Treesitter
-- parsers, installs the Mason language servers, and waits for all of them, so
-- test boots don't start (and kill) installs.
vim.api.nvim_exec_autocmds("UIEnter", {}) -- fire VeryLazy; headless has no UI

-- Mason packages for the configured language servers. mason-lspconfig skips its
-- ensure_installed when headless, so this setup installs them itself.
local function server_packages()
  local to_package = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
  local packages = {}
  for server, server_opts in pairs(LazyVim.opts("nvim-lspconfig").servers or {}) do
    local skip = type(server_opts) == "table" and (server_opts.enabled == false or server_opts.mason == false)
    if to_package[server] and server_opts and not skip then
      table.insert(packages, to_package[server])
    end
  end
  return packages
end

local registry = require("mason-registry")
registry.refresh(function()
  for _, name in ipairs(server_packages()) do
    local pkg = registry.get_package(name)
    if not pkg:is_installed() and not pkg:is_installing() then
      pkg:install()
    end
  end
end)

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
  for _, pkg in ipairs(registry.get_all_packages()) do
    if pkg:is_installing() then
      table.insert(todo, "mason " .. pkg.name .. " (installing)")
    end
  end
  local wanted = vim.list_extend(vim.deepcopy(LazyVim.opts("mason.nvim").ensure_installed or {}), server_packages())
  for _, name in ipairs(wanted) do
    if not registry.is_installed(name) then
      table.insert(todo, "mason " .. name)
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
