-- The current toggle inventory, registered explicitly so a future toggle does
-- not silently become persistent. Local choices become defaults for buffers
-- opened in later sessions.
local M = {}

local state = require("toggle_state")

local function persist(key, toggle, mapping, opts)
  state.persist(key, toggle, opts):map(mapping)
  return toggle
end

--- Whether `win` is an ordinary window holding a file (or a new, unnamed one):
--- not the Dashboard, a terminal, help, a panel or a float.
---@param win integer
local function file_window(win)
  return vim.api.nvim_win_get_config(win).relative == "" and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
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
  -- The global value reaches every file opened later, even in the Dashboard's
  -- window; the local one only a file already open, never the Dashboard.
  vim.api.nvim_set_option_value(option, saved and on or off, { scope = "global" })
  if file_window(0) then
    vim.api.nvim_set_option_value(option, saved and on or off, { scope = "local" })
  end
  -- Filetype defaults (notably prose wrap/spell and JSON conceal) run after
  -- startup restoration. A saved preference wins once, without resetting a
  -- later choice when the user returns to an already initialized buffer.
  if state.has(key) then
    local restored = {}
    local function restore(buf)
      if restored[buf] or not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if file_window(win) then
          vim.api.nvim_set_option_value(option, saved and on or off, { scope = "local", win = win })
          restored[buf] = true
        end
      end
    end
    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
      group = vim.api.nvim_create_augroup("persistent_option_" .. option, { clear = true }),
      callback = function(args)
        vim.schedule(function()
          restore(args.buf)
        end)
      end,
    })
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf) ~= "" then
        restore(buf)
      end
    end
  end
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
  -- Restored directly: the toggle's setter shows LazyFormat's status, which
  -- would pop up on every startup.
  local default = vim.g.autoformat == nil or vim.g.autoformat
  vim.g.autoformat = state.get("format.global", default)
  persist("format.global", LazyVim.format.snacks_toggle(), "<leader>uf", { default = default, restore = false })

  -- vim.b.autoformat outranks the global toggle, so it's set only when a
  -- buffer choice was saved: otherwise <leader>uf would miss visited buffers.
  restore_per_buffer("format.buffer", { "BufReadPost", "BufNewFile" }, function(buf, enabled)
    vim.b[buf].autoformat = enabled
  end)
  persist("format.buffer", LazyVim.format.snacks_toggle(true), "<leader>uF", { restore = false })
end

--- Line numbers: one choice for every file window, shown in no other window.
--- Toggling works from anywhere; on the Dashboard it only sets the choice.
local function line_numbers()
  local number_default = vim.o.number or vim.o.relativenumber
  local relative_default = vim.o.relativenumber
  local number = state.get("editor.line_numbers", number_default)
  local relative = state.get("editor.relative_number", relative_default)

  local function show(win)
    local file = file_window(win)
    vim.api.nvim_set_option_value("number", file and number, { scope = "local", win = win })
    vim.api.nvim_set_option_value("relativenumber", file and number and relative, { scope = "local", win = win })
  end

  -- Floats keep their own (zen, previews), as their plugins set them.
  local function apply()
    vim.opt_global.number = number
    vim.opt_global.relativenumber = number and relative
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative == "" then
        show(win)
      end
    end
  end

  -- Synchronous, so a plugin setting its own window options afterwards wins.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "TermOpen" }, {
    group = vim.api.nvim_create_augroup("line_numbers", { clear = true }),
    callback = function(args)
      for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
          show(win)
        end
      end
    end,
  })
  apply()

  persist(
    "editor.line_numbers",
    Snacks.toggle({
      id = "line_number",
      name = "Line Numbers",
      get = function()
        return number
      end,
      set = function(enabled)
        number = enabled
        apply()
      end,
    }),
    "<leader>ul",
    { default = number_default, restore = false }
  )
  persist(
    "editor.relative_number",
    Snacks.toggle({
      id = "relativenumber",
      name = "Relative Number",
      get = function()
        return relative
      end,
      set = function(enabled)
        relative = enabled
        apply()
      end,
    }),
    "<leader>uL",
    { default = relative_default, restore = false }
  )
end

local function local_options()
  local_option("editor.spell", "spell", "<leader>us")
  local_option("editor.wrap", "wrap", "<leader>uw")

  line_numbers()

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
      on = 2,
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
  -- The key keeps its old name, so the saved choice survives the rename.
  local block_guide = Snacks.toggle.indent()
  block_guide.opts.name = "Block Guide"
  persist("ui.indent_guides", block_guide, "<leader>ug")
  persist("ui.smooth_scroll", Snacks.toggle.scroll(), "<leader>uS")
  require("cursor_line").setup()
  persist("ui.cursor_line", require("cursor_line").toggle(), "<leader>uH")
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
        name = "Animations",
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
