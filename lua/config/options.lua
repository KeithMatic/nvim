-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Rounded borders on every float that doesn't pick its own: LSP hover and
-- signature help, blink.cmp, which-key, Mason, and Snacks' `border = true`.
vim.o.winborder = "rounded"

-- Dropbar highlights bar and menu entries as the mouse moves over them.
vim.o.mousemoveevent = true

-- No Trouble symbols in the statusline: Dropbar shows the Breadcrumbs.
vim.g.trouble_lualine = false

-- Trailing spaces aren't marked: on a blank line inside a block they'd draw a
-- dashed line across it. Formatting on save removes them anyway.
vim.opt.listchars = { tab = "> ", nbsp = "+" }

-- No command line row: noice draws the cmdline and messages, and Neovim drops
-- the row when it takes over (on VeryLazy). Starting without it keeps the
-- window one size, so the Dashboard is laid out once rather than redrawn a
-- row lower with its colour strip briefly over the header.
vim.o.cmdheight = 0
