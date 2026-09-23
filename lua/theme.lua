-- Themes: the curated list of dark themes, and persistence. Every theme change,
-- however it happens (the picker, `:colorscheme`), goes through one
-- ColorScheme hook, which saves the theme so the next start restores it. Live
-- previews in the picker and the theme applied at startup aren't saved.
local M = {}

-- The only themes the picker offers.
M.themes = {
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha",
  "tokyonight-night",
  "tokyonight-storm",
  "tokyonight-moon",
}

-- Used when nothing is saved, or the saved theme won't load.
M.default = "tokyonight-moon"

local state_file = vim.fn.stdpath("state") .. "/theme.json"

--- The saved state, or an empty table when it's missing or unreadable.
---@return {theme?: string}
local function read_state()
  local ok, state = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state_file), "\n"))
  end)
  return ok and type(state) == "table" and state or {}
end

--- Merge `changes` into the saved state.
---@param changes table
local function save_state(changes)
  local state = vim.tbl_extend("force", read_state(), changes)
  vim.fn.mkdir(vim.fs.dirname(state_file), "p")
  vim.fn.writefile({ vim.json.encode(state) }, state_file)
end

-- True while startup applies the saved theme (or a fallback), which is never saved.
local restoring = false

--- Whether a colorscheme picker is open, so theme changes are only previews.
local function previewing()
  return #Snacks.picker.get({ source = "colorschemes", tab = false }) > 0
end

--- The hook that runs on every theme change.
local function on_change()
  if not (restoring or previewing()) then
    save_state({ theme = vim.g.colors_name })
  end
end

--- LazyVim's `colorscheme` option: set up the change hook, then apply the
--- saved theme, falling back to the default.
function M.load()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("theme", { clear = true }),
    callback = on_change,
  })
  -- Scheduled, so it also covers LazyVim's own fallback (habamax) should the default fail too.
  restoring = true
  vim.schedule(function()
    restoring = false
  end)
  local saved = read_state().theme
  if not (type(saved) == "string" and pcall(vim.cmd.colorscheme, saved)) then
    vim.cmd.colorscheme(M.default)
  end
end

--- A colorscheme picker, with live preview, limited to the curated themes.
function M.pick()
  Snacks.picker.colorschemes({
    transform = function(item)
      return vim.list_contains(M.themes, item.text)
    end,
  })
end

return M
