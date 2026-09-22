local h = require("harness")

local extras = {
  "lang.typescript",
  "lang.python",
  "lang.go",
  "lang.rust",
  "lang.clangd",
  "lang.tailwind",
  "lang.json",
  "lang.yaml",
  "lang.docker",
  "lang.sql",
  "lang.markdown",
  "lang.toml",
  "formatting.prettier",
  "linting.eslint",
}

h.test("every language extra shows as enabled, from config rather than the extras UI", function()
  local by_name = {}
  for _, extra in ipairs(LazyVim.extras.get()) do
    by_name[extra.name] = extra
  end
  for _, name in ipairs(extras) do
    local extra = by_name[name]
    h.eq(true, extra ~= nil and extra.enabled, name .. " enabled")
    h.eq(false, extra and extra.managed, name .. " enabled by an explicit import, not the extras UI")
  end
end)

h.test("no AI extras are enabled", function()
  local enabled = {}
  for _, extra in ipairs(LazyVim.extras.get()) do
    if extra.enabled and extra.name:match("^ai%.") then
      table.insert(enabled, extra.name)
    end
  end
  h.eq({}, enabled)
end)

-- A throwaway project, so root-seeking servers (gopls, rust-analyzer, tailwind) have a root.
local project = vim.fn.tempname()
vim.fn.mkdir(project, "p")
local function write(name, lines)
  vim.fn.writefile(lines, project .. "/" .. name)
end
write("go.mod", { "module example.com/scratch", "", "go 1.22" })
write("Cargo.toml", { "[package]", 'name = "scratch"', 'version = "0.1.0"', 'edition = "2021"' })
vim.fn.mkdir(project .. "/src", "p")
write("src/main.rs", { "fn main() {}" })
write("tailwind.config.js", { "module.exports = {}" })
write("package.json", { "{}" })
write("eslint.config.js", { "export default [];" })
write(".sqlfluff", { "[sqlfluff]", "dialect = ansi" }) -- conform only runs sqlfluff in a sqlfluff project

--- Open `file` (created empty if missing) in the scratch project and return its buffer.
local function open(file)
  local path = project .. "/" .. file
  if vim.fn.filereadable(path) == 0 then
    write(file, {})
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

--- Names of the LSP clients attached to `buf`, once `want` attaches or 20s pass.
local function attached(buf, want)
  vim.wait(20000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = want }) > 0
  end, 100)
  return vim.tbl_map(function(c)
    return c.name
  end, vim.lsp.get_clients({ bufnr = buf }))
end

--- Assert that `want` is among `names`.
local function includes(names, want, what)
  h.eq(true, vim.list_contains(names, want), ("%s (got %s)"):format(what, vim.inspect(names)))
end

--- Assert that `server` attaches to `file`.
local function assert_attaches(file, server)
  includes(attached(open(file), server), server, server .. " attached to " .. file)
end

--- Formatters conform would run for `buf`.
local function formatters(buf)
  return vim.tbl_map(function(f)
    return f.name
  end, require("conform").list_formatters_to_run(buf))
end

-- Per file: expected filetype, LSP server and conform formatter. No formatter
-- means the language server formats, LazyVim's default for those languages.
local cases = {
  { file = "app.ts", ft = "typescript", server = "vtsls", formatter = "prettier" },
  { file = "App.tsx", ft = "typescriptreact", server = "vtsls", formatter = "prettier" },
  { file = "app.js", ft = "javascript", server = "vtsls", formatter = "prettier" },
  { file = "App.jsx", ft = "javascriptreact", server = "vtsls", formatter = "prettier" },
  { file = "index.html", ft = "html", server = "html", formatter = "prettier" },
  { file = "style.css", ft = "css", server = "cssls", formatter = "prettier" },
  { file = "page.mdx", ft = "mdx", server = "mdx_analyzer", formatter = "prettier" },
  { file = "data.json", ft = "json", server = "jsonls", formatter = "prettier" },
  { file = "config.yaml", ft = "yaml", server = "yamlls", formatter = "prettier" },
  { file = "README.md", ft = "markdown", server = "marksman", formatter = "prettier" },
  { file = "main.py", ft = "python", server = "pyright" },
  { file = "main.go", ft = "go", server = "gopls", formatter = "goimports" },
  { file = "src/main.rs", ft = "rust", server = "rust-analyzer" },
  { file = "main.c", ft = "c", server = "clangd" },
  { file = "main.cpp", ft = "cpp", server = "clangd" },
  { file = "Dockerfile", ft = "dockerfile", server = "dockerls" },
  {
    file = "compose.yaml",
    ft = "yaml.docker-compose",
    server = "docker_compose_language_service",
    formatter = "prettier",
  },
  { file = "query.sql", ft = "sql", formatter = "sqlfluff" },
  { file = "Cargo.toml", ft = "toml", server = "taplo" },
  { file = "init.lua", ft = "lua", server = "lua_ls", formatter = "stylua" },
}

for _, case in ipairs(cases) do
  local name = case.file .. ": " .. case.ft .. " filetype"
  name = name .. (case.server and (", " .. case.server .. " attaches") or "")
  name = name .. (case.formatter and (", formats with " .. case.formatter) or "")
  h.test(name, function()
    local buf = open(case.file)
    h.eq(case.ft, vim.bo[buf].filetype, case.file .. " filetype")
    if case.server then
      assert_attaches(case.file, case.server)
    end
    if case.formatter then
      includes(formatters(buf), case.formatter, case.formatter .. " formats " .. case.file)
    end
  end)
end

h.test("Emmet attaches to markup and stylesheets", function()
  for _, file in ipairs({ "index.html", "style.css", "App.tsx" }) do
    assert_attaches(file, "emmet_language_server")
  end
end)

h.test("Tailwind attaches in a Tailwind project", function()
  assert_attaches("index.html", "tailwindcss")
end)

h.test("ESLint attaches to JavaScript and TypeScript", function()
  for _, file in ipairs({ "app.ts", "App.tsx", "app.js" }) do
    assert_attaches(file, "eslint")
  end
end)

h.test("MDX files get Treesitter highlighting", function()
  local buf = open("page.mdx")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# Title", "", "Some *text*." })
  vim.treesitter.get_parser(buf):parse()
  local captures = vim.tbl_map(function(c)
    return c.capture
  end, vim.treesitter.get_captures_at_pos(buf, 0, 2))
  includes(captures, "markup.heading.1", "heading highlight on the mdx title")
end)
