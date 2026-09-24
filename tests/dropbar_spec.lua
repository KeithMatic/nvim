local h = require("harness")

local leader = vim.g.mapleader

local function mapping(lhs)
  return vim.fn.maparg(lhs, "n", false, true)
end

h.test("Dropbar and native fzf are installed with mouse movement enabled", function()
  local plugins = require("lazy.core.config").plugins
  local dropbar = plugins["dropbar.nvim"]
  h.eq(true, dropbar ~= nil, "dropbar.nvim installed")
  h.eq(true, plugins["telescope-fzf-native.nvim"] ~= nil, "telescope-fzf-native.nvim installed")
  h.eq(true, vim.o.mousemoveevent, "mousemoveevent")
end)

h.test("Dropbar owns the Breadcrumbs mappings", function()
  require("lazy").load({ plugins = { "dropbar.nvim" } })
  h.eq("Pick Breadcrumbs", mapping(leader .. ";").desc)
  h.eq("Breadcrumbs Context Start", mapping("[;").desc)
  h.eq("Breadcrumbs Next Context", mapping("];").desc)
  h.eq("Toggle Breadcrumbs", mapping(leader .. "kb").desc)
end)

h.test("Dropbar menus use the Menu keys without losing the defaults", function()
  require("lazy").load({ plugins = { "dropbar.nvim" } })
  local opts = require("dropbar.configs").opts
  for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>", "<CR>", "<Esc>", "q", "i", "<LeftMouse>" }) do
    h.eq(true, opts.menu.keymaps[key] ~= nil, "normal menu mapping " .. key)
  end
  for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>", "<CR>", "<LeftMouse>" }) do
    h.eq(true, opts.fzf.keymaps[key] ~= nil, "fuzzy menu mapping " .. key)
  end
end)

h.test("Dropbar keeps the existing selection provider", function()
  require("lazy").load({ plugins = { "dropbar.nvim" } })
  h.eq(false, vim.ui.select == require("dropbar.utils.menu").select, "vim.ui.select is not Dropbar")
end)

h.test("Lspsaga no longer owns Breadcrumbs", function()
  require("lazy").load({ plugins = { "lspsaga.nvim" } })
  h.eq(false, require("lspsaga").config.symbol_in_winbar.enable, "Lspsaga Breadcrumbs")
  h.eq("Rename", mapping(leader .. "kr").desc)
  h.eq("Outline", mapping(leader .. "ko").desc)
end)
