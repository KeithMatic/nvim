-- The cheat sheet: the README, every keymap and feature, read-only in a float
-- over whatever is open, the way LazyVim shows its news. <leader>sK opens it
-- from anywhere (lua/config/keymaps.lua), k from the Dashboard; q closes it.
local M = {}

M.file = vim.fn.stdpath("config") .. "/README.md"

--- Open the cheat sheet. It's the README's text in a scratch buffer, not the
--- file: nothing lints, saves or language-serves it.
---@return snacks.win
function M.open()
  return Snacks.win({
    text = vim.fn.readfile(M.file),
    width = 0.8,
    height = 0.8,
    border = "rounded",
    title = " Keymaps & Features ",
    title_pos = "center",
    bo = { filetype = "markdown", modifiable = false },
    wo = { spell = false, wrap = false, signcolumn = "yes", statuscolumn = " ", conceallevel = 3 },
  })
end

return M
