-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- AstroNvim's shortcuts use Celeste's gc/gcc; project search remains on <leader>sg.
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })

-- Re-assert Celeste's insertion helpers after LazyVim's built-in aliases load.
vim.keymap.set(
  "n",
  "gco",
  '<Cmd>lua require("celeste_comment").H.insert_comment("below")<CR>',
  { desc = "Add comment below" }
)
vim.keymap.set(
  "n",
  "gcO",
  '<Cmd>lua require("celeste_comment").H.insert_comment("above")<CR>',
  { desc = "Add comment above" }
)

-- The code runner (:RunFile, set up in autocmds.lua). <leader>cx is free in LazyVim's "code" group.
vim.keymap.set("n", "<leader>cx", "<Cmd>RunFile<CR>", { desc = "Run File" })

-- Show or hide the statusline's filename (lua/statusline.lua). <leader>uN is free in LazyVim's "ui" group.
require("statusline").filename_toggle():map("<leader>uN")
