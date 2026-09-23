-- Editing behaviour: the completion Tab chain.

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
}
