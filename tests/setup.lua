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

-- Every Mason package the sandbox needs: LazyVim's tools plus the servers, deduplicated.
-- LazyVim installs its own list, but the rust and clangd extras both add codelldb, and
-- its loop stops at the second install() of a package already installing, so the
-- tools after it would never install on a fresh sandbox.
local function wanted_packages()
  local tools = vim.list_extend(vim.deepcopy(LazyVim.opts("mason.nvim").ensure_installed or {}), server_packages())
  return LazyVim.dedup(tools)
end

local registry = require("mason-registry")
registry.refresh(function()
  for _, name in ipairs(wanted_packages()) do
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
  for _, name in ipairs(wanted_packages()) do
    if not registry.is_installed(name) then
      table.insert(todo, "mason " .. name)
    end
  end
  return todo
end

-- Mason keeps a package's install handle once the install ends, so a closed
-- handle on a package that isn't installed means the install failed. Nothing
-- retries it, so waiting longer won't help.
local function install_failed(pkg)
  local handle = pkg:get_install_handle():or_else(nil)
  return not pkg:is_installed() and handle ~= nil and handle:is_closed()
end

local function failed()
  local names = {}
  for _, name in ipairs(wanted_packages()) do
    if install_failed(registry.get_package(name)) then
      table.insert(names, name)
    end
  end
  return names
end

-- Installs are queued asynchronously, so only trust "nothing missing" once it has held for a few seconds.
local idle_since
local done = vim.wait(10 * 60 * 1000, function()
  if #failed() > 0 then
    return true
  end
  if #missing() > 0 then
    idle_since = nil
    return false
  end
  idle_since = idle_since or vim.uv.now()
  return vim.uv.now() - idle_since > 3000
end, 200)

-- Why the named Mason packages haven't installed: each one's install output
-- (what its installer printed, then Mason's error), plus the last errors and
-- warnings in Mason's log if any of them printed nothing (never started).
local function explain(names)
  local out, unexplained = {}, false
  for _, name in ipairs(names) do
    local handle = registry.get_package(name):get_install_handle():or_else(nil)
    local buffers = handle and handle.stdio_sink.buffers or { stdout = {}, stderr = {} }
    local output = vim.trim(table.concat(buffers.stdout) .. table.concat(buffers.stderr))
    if output == "" then
      unexplained = true
    else
      table.insert(out, ("--- mason %s install output:\n%s"):format(name, output))
    end
  end
  if unexplained then
    local logfile = require("mason-core.log").outfile
    local ok, lines = pcall(vim.fn.readfile, logfile)
    local problems = vim.tbl_filter(function(line)
      return line:match("^%[ERROR") or line:match("^%[WARN")
    end, ok and lines or {})
    problems = vim.list_slice(problems, math.max(1, #problems - 19))
    table.insert(out, ("--- last errors and warnings in %s:\n%s"):format(logfile, table.concat(problems, "\n")))
  end
  return table.concat(out, "\n")
end

local install_failures = failed()
if #install_failures > 0 then
  io.stdout:write("\nSandbox setup failed installing: mason " .. table.concat(install_failures, ", mason ") .. "\n")
  io.stdout:write(explain(install_failures) .. "\n")
  vim.cmd("cquit 1")
elseif not done then
  io.stdout:write("\nSandbox setup timed out waiting for: " .. table.concat(missing(), ", ") .. "\n")
  local not_installed = vim.tbl_filter(function(name)
    return not registry.is_installed(name)
  end, wanted_packages())
  io.stdout:write(explain(not_installed) .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qall!")
