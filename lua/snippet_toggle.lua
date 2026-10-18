-- The Snippet toggle: hides or shows Snippet suggestions in the completion
-- menu, saved like the other toggles (lua/persistent_toggles.lua): <leader>uk,
-- or <C-q> while the menu is open. Hidden means every item of the Snippet
-- kind, which friendly-snippets' items and a language server's snippets share;
-- a function whose call expands with its arguments is a Function, so it stays.
local M = {}

local shown = true

--- blink.cmp's `sources.transform_items`: every source's items pass through it
--- each time they're fetched, so a change applies from the next menu.
---@param items table[] blink.cmp's completion items
---@return table[]
function M.filter(_, items)
  if shown then
    return items
  end
  local snippet = require("blink.cmp.types").CompletionItemKind.Snippet
  return vim.tbl_filter(function(item)
    return item.kind ~= snippet
  end, items)
end

--- Fetch an open menu's items again, so it shows the change at once. Cancel
--- puts back the typed word a selected item's preview replaced.
local function refresh_menu()
  local cmp = package.loaded["blink.cmp"]
  if cmp and cmp.is_menu_visible() then
    cmp.cancel({ callback = cmp.show })
  end
end

local toggle

--- One toggle, so <C-q> flips the one persistent_toggles saves.
function M.toggle()
  toggle = toggle
    or Snacks.toggle({
      name = "Snippet Suggestions",
      get = function()
        return shown
      end,
      set = function(state)
        shown = state
        refresh_menu()
      end,
    })
  return toggle
end

--- <C-q> in blink.cmp's keymap: flips the toggle while the menu is open, and
--- otherwise returns nothing, so the key falls back to its own meaning.
---@return true?
function M.flip_in_menu()
  if require("blink.cmp").is_menu_visible() then
    M.toggle():toggle()
    return true
  end
end

return M
