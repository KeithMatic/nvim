-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Rounded borders on every float that doesn't pick its own: LSP hover and
-- signature help, blink.cmp, which-key, Mason, and Snacks' `border = true`.
vim.o.winborder = "rounded"

-- No Trouble symbols in the statusline: the Breadcrumbs (lspsaga) show them.
vim.g.trouble_lualine = false
