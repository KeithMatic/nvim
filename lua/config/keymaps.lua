-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- The code runner (:RunFile, set up in autocmds.lua). <leader>cx is free in LazyVim's "code" group.
vim.keymap.set("n", "<leader>cx", "<Cmd>RunFile<CR>", { desc = "Run File" })

-- Show or hide the statusline's filename (lua/statusline.lua). <leader>uN is free in LazyVim's "ui" group.
require("statusline").filename_toggle():map("<leader>uN")
