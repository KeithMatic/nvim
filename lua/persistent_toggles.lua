-- The current toggle inventory, registered explicitly so a future toggle does
-- not silently become persistent. Local choices become defaults for buffers
-- opened in later sessions.
local M = {}

local state = require("toggle_state")

local function persist(key, toggle, mapping, opts)
  state.persist(key, toggle, opts):map(mapping)
  return toggle
end

local function local_option(key, option, mapping, opts)
  opts = opts or {}
  local on = opts.on
  if on == nil then
    on = true
  end
  local off = opts.off
  if off == nil then
    off = false
  end
  local default = vim.api.nvim_get_option_value(option, { scope = "global" }) == on
  local saved = state.get(key, default)
  vim.api.nvim_set_option_value(option, saved and on or off, { scope = "global" })
  vim.api.nvim_set_option_value(option, saved and on or off, { scope = "local" })
  return persist(key, Snacks.toggle.option(option, opts), mapping, { default = default, restore = false })
end

--- Give each buffer a saved buffer-local choice once, when `events` set it up,
--- scheduled after LazyVim's own handlers for them. Once, because re-applying
--- on every visit would undo choices made in other buffers; and only when a
--- choice was saved, so LazyVim's defaults apply otherwise (whichever buffer is
--- current at startup, often the Dashboard, says nothing about files).
---@param key string
---@param events string[]
---@param apply fun(buf: integer, value: boolean)
local function restore_per_buffer(key, events, apply)
  local restored = {}
  local function restore(buf)
    if restored[buf] or not state.has(key) or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    restored[buf] = true
    apply(buf, state.get(key, true))
  end
  vim.api.nvim_create_autocmd(events, {
    group = vim.api.nvim_create_augroup("persistent_toggle_defaults", { clear = false }),
    callback = function(args)
      vim.schedule(function()
        restore(args.buf)
      end)
    end,
  })
  -- Files opened before this ran (from the command line) are set up already.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
      restore(buf)
    end
  end
end

local function formats()
  persist("format.global", LazyVim.format.snacks_toggle(), "<leader>uf")

  -- vim.b.autoformat outranks the global toggle, so it's set only when a
  -- buffer choice was saved: otherwise <leader>uf would miss visited buffers.
  restore_per_buffer("format.buffer", { "BufReadPost", "BufNewFile" }, function(buf, enabled)
    vim.b[buf].autoformat = enabled
  end)
  persist("format.buffer", LazyVim.format.snacks_toggle(true), "<leader>uF", { restore = false })
end

local function local_options()
  local_option("editor.spell", "spell", "<leader>us")
  local_option("editor.wrap", "wrap", "<leader>uw")

  local number_default = vim.o.number or vim.o.relativenumber
  local relative_default = vim.o.relativenumber
  local number = state.get("editor.line_numbers", number_default)
  local relative = state.get("editor.relative_number", relative_default)
  vim.opt_global.number = number
  vim.opt_global.relativenumber = number and relative
  vim.opt_local.number = number
  vim.opt_local.relativenumber = number and relative
  persist("editor.line_numbers", Snacks.toggle.line_number(), "<leader>ul", {
    default = number_default,
    restore = false,
  })
  persist(
    "editor.relative_number",
    Snacks.toggle.option("relativenumber"),
    "<leader>uL",
    { default = relative_default, restore = false }
  )

  local conceal = vim.o.conceallevel > 0 and vim.o.conceallevel or 2
  local_option("editor.conceal", "conceallevel", "<leader>uc", { off = 0, on = conceal })
end

local function treesitter()
  restore_per_buffer("editor.treesitter", { "FileType" }, function(buf, enabled)
    if enabled ~= (vim.treesitter.highlighter.active[buf] ~= nil) then
      pcall(vim.treesitter[enabled and "start" or "stop"], buf)
    end
  end)
  persist("editor.treesitter", Snacks.toggle.treesitter(), "<leader>uT", { restore = false })
end

local function inlay_hints()
  if not vim.lsp.inlay_hint then
    return
  end
  restore_per_buffer("lsp.inlay_hints", { "LspAttach" }, function(buf, enabled)
    pcall(vim.lsp.inlay_hint.enable, enabled, { bufnr = buf })
  end)
  persist("lsp.inlay_hints", Snacks.toggle.inlay_hints(), "<leader>uh", { restore = false })
end

local function ordinary()
  persist("diagnostics.enabled", Snacks.toggle.diagnostics(), "<leader>ud")
  persist(
    "ui.tabline",
    Snacks.toggle.option("showtabline", {
      off = 0,
      on = vim.o.showtabline > 0 and vim.o.showtabline or 2,
      global = true,
      name = "Tabline",
    }),
    "<leader>uA"
  )
  persist(
    "ui.dark_background",
    Snacks.toggle.option("background", { off = "light", on = "dark", global = true, name = "Dark Background" }),
    "<leader>ub"
  )
  persist("ui.indent_guides", Snacks.toggle.indent(), "<leader>ug")
  persist("ui.smooth_scroll", Snacks.toggle.scroll(), "<leader>uS")
end

-- A fresh process starts these off already, so their saved state is never
-- applied (forcing them off would load the profiler and warn it isn't running).
local function temporary_modes()
  local function temporary(key, toggle, mapping)
    return persist(key, toggle, mapping, { restore = false })
  end

  temporary("mode.dim", Snacks.toggle.dim(), "<leader>uD")
  temporary("mode.zoom", Snacks.toggle.zoom(), "<leader>wm"):map("<leader>uZ")
  temporary("mode.zen", Snacks.toggle.zen(), "<leader>uz")
  temporary("mode.profiler", Snacks.toggle.profiler(), "<leader>dpp")
  temporary("mode.profiler_highlights", Snacks.toggle.profiler_highlights(), "<leader>dph")
end

local function animation()
  local default = vim.g.minianimate_disable ~= true
  local saved = state.get("ui.animation", default)
  vim.g.minianimate_disable = not saved
  vim.schedule(function()
    persist(
      "ui.animation",
      Snacks.toggle({
        name = "Mini Animate",
        get = function()
          return not vim.g.minianimate_disable
        end,
        set = function(enabled)
          vim.g.minianimate_disable = not enabled
        end,
      }),
      "<leader>ua",
      { default = default, restore = false }
    )
  end)
end

local function git_signs()
  LazyVim.on_load("gitsigns.nvim", function()
    local config = require("gitsigns.config").config
    persist(
      "ui.git_signs",
      Snacks.toggle({
        name = "Git Signs",
        get = function()
          return config.signcolumn
        end,
        set = function(enabled)
          require("gitsigns").toggle_signs(enabled)
        end,
      }),
      "<leader>uG"
    )
  end)
end

-- LazyVim maps <leader>up in mini.pairs' config, so this runs after it.
local function mini_pairs()
  LazyVim.on_load("mini.pairs", function()
    persist(
      "editor.pairs",
      Snacks.toggle({
        name = "Mini Pairs",
        get = function()
          return not vim.g.minipairs_disable
        end,
        set = function(enabled)
          vim.g.minipairs_disable = not enabled
        end,
      }),
      "<leader>up",
      { default = true }
    )
  end)
end

function M.setup()
  formats()
  local_options()
  treesitter()
  inlay_hints()
  ordinary()
  temporary_modes()
  animation()
  git_signs()
  mini_pairs()
end

return M
