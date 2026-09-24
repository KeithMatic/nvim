-- Languages LazyVim has no extra for: HTML, CSS, Emmet and MDX, plus the gaps
-- in the extras imported in config/lazy.lua (Rust's server, SQL's server and dialect).

-- The TypeScript SDK bundled with vtsls, which the typescript extra installs.
local vtsls_tsdk = "$MASON/packages/vtsls/node_modules/@vtsls/language-server/node_modules/typescript/lib"

-- MDX gets its own filetype, which mdx_analyzer expects. Registered now for files
-- opened at startup, and again on VeryLazy to override the markdown extra's
-- "markdown.mdx". That override relies on config/lazy.lua importing this file
-- after the extras, so this VeryLazy callback runs after theirs.
local function mdx_filetype()
  vim.filetype.add({ extension = { mdx = "mdx" } })
end
mdx_filetype()
LazyVim.on_very_lazy(mdx_filetype)
-- MDX is Markdown plus JSX; the Markdown parser highlights it well enough.
vim.treesitter.language.register("markdown", "mdx")

-- The docker extra's compose server only serves "yaml.docker-compose", which
-- nothing assigns; yaml stays first, so yamlls and prettier still apply.
vim.filetype.add({
  filename = {
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
  },
})

-- SQL is Postgres. The sql extra ships no server, and sqlfluff refuses to run
-- without a dialect, which only a project's .sqlfluff used to give it.
local sql_dialect = "postgres"

--- sqlfluff arguments to `verb` (lint or format) `filename` from stdin: config is
--- found from the file, not Neovim's cwd, and a project's .sqlfluff dialect wins.
local function sqlfluff_args(verb, filename, extra)
  local args = { verb, "--stdin-filename", filename }
  if not vim.fs.root(filename, ".sqlfluff") then
    table.insert(args, "--dialect=" .. sql_dialect)
  end
  return vim.list_extend(vim.list_extend(args, extra or {}), { "-" })
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
        emmet_language_server = {},
        mdx_analyzer = {
          -- mdx-analyzer won't start without a TypeScript SDK: use the project's, else vtsls's.
          before_init = function(_, config)
            local tsdk = config.root_dir and require("lspconfig.util").get_typescript_server_path(config.root_dir) or ""
            if tsdk == "" then
              tsdk = vim.fn.expand(vtsls_tsdk)
            end
            config.init_options.typescript.tsdk = tsdk
          end,
        },
        -- Without a postgres-language-server.jsonc it still checks syntax;
        -- add one (with a connection) for schema-aware completion and type checks.
        postgres_lsp = { workspace_required = false },
      },
    },
  },
  -- The rust extra's rustaceanvim expects rust-analyzer on PATH but doesn't install it;
  -- Mason's bin dir comes first on PATH, ahead of rustup's (possibly component-less) proxy.
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "rust-analyzer" } },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "css", "scss" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { mdx = { "prettier" } },
      formatters = {
        sqlfluff = {
          require_cwd = false,
          args = function(_, ctx)
            return sqlfluff_args("format", ctx.filename)
          end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        -- A function, so the arguments are built for the buffer being linted.
        sqlfluff = function()
          local filename = vim.api.nvim_buf_get_name(0)
          return vim.tbl_extend("force", require("lint.linters.sqlfluff"), {
            args = sqlfluff_args("lint", filename, { "--format=json" }),
          })
        end,
      },
    },
  },
}
