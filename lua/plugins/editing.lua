-- Editing behaviour: the completion Tab chain and smart strings.

return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        -- "default" rather than LazyVim's "enter": <CR> never accepts a completion.
        -- It keeps <C-n>/<C-p>, the arrow keys and <C-y> for the menu.
        preset = "default",
        -- The only insert-mode <Tab>: accept → snippet forward → tabout → indent.
        -- Setting it here also stops LazyVim adding its own <Tab> chain, which
        -- would accept AI suggestions (no AI extras are enabled).
        ["<Tab>"] = {
          "select_and_accept",
          "snippet_forward",
          function()
            return require("tabout").tabout()
          end,
          "fallback",
        },
      },
    },
  },
  -- Smart strings: typing a `{…}` placeholder turns a Python string into an
  -- f-string, and typing `${` turns a JS/TS quoted string into a template literal.
  -- It loads per filetype on its own, so it must not be lazy-loaded.
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
    init = function()
      -- Lua conversion (to `("…"):format()`) is on by default despite the README;
      -- the variable is spelled "disabled" in the code, "disable" in the README.
      vim.g.puppeteer_disabled_filetypes = { "lua" }
    end,
  },
}
