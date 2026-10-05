-- The Git layer (<leader>gH): a hunk review with one key per action. Entering
-- lands on the first hunk unless the cursor is already on one, and shows the
-- gutter's git signs until it's left, when they go back to what <leader>uG
-- has them set to (even if it was pressed in the layer).
-- j/k go between hunks in Normal mode only, so V j j s still stages lines.
local icons = require("util.icons")

local function gs()
  return require("gitsigns")
end

--- A key's action: gitsigns' `name`, called with `...`.
local function call(name, ...)
  local args = { ... }
  return function()
    gs()[name](unpack(args))
  end
end

--- Like `call`, given the selected lines: for part of a hunk.
local function on_selection(name)
  return function()
    gs()[name]({ vim.fn.line("v"), vim.fn.line(".") })
  end
end

--- Whether the cursor is on one of the buffer's hunks (a deletion sits on the
--- line above where the lines were).
local function on_hunk()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  return vim.iter(gs().get_hunks() or {}):any(function(hunk)
    local first = math.max(hunk.added.start, 1)
    return line >= first and line <= first + math.max(hunk.added.count, 1) - 1
  end)
end

-- The signs before entering: what they go back to unless <leader>uG has
-- saved a choice (lua/persistent_toggles.lua).
local signs_before

return require("layer").new({
  name = "Git",
  icon = icons.git.Branch,
  colour = "GitSignsChange",
  enter = function()
    if not vim.b.gitsigns_status_dict then
      vim.notify("Not a file git tracks", vim.log.levels.INFO, { title = "Git layer" })
      return false
    end
    -- Before showing the signs: that refreshes gitsigns, and nav_hunk finds
    -- no hunks until it's done.
    if not on_hunk() then
      gs().nav_hunk("first")
    end
    -- gitsigns' own setting, read as persistent_toggles.lua reads it.
    signs_before = require("gitsigns.config").config.signcolumn
    gs().toggle_signs(true)
  end,
  leave = function()
    gs().toggle_signs(require("toggle_state").get("ui.git_signs", signs_before))
  end,
  keys = {
    n = {
      { "n", call("nav_hunk", "next"), { desc = "next hunk" } },
      { "j", call("nav_hunk", "next"), { desc = "next hunk" } },
      { "p", call("nav_hunk", "prev"), { desc = "previous hunk" } },
      { "k", call("nav_hunk", "prev"), { desc = "previous hunk" } },
      { "s", call("stage_hunk"), { desc = "stage hunk" } },
      -- Deprecated in gitsigns (stage_hunk on a staged hunk unstages it), but
      -- it still works, and LazyVim's <leader>ghu uses it too.
      { "u", call("undo_stage_hunk"), { desc = "undo stage" } },
      { "r", call("reset_hunk"), { desc = "reset hunk" } },
      { "S", call("stage_buffer"), { desc = "stage file" } },
      { "R", call("reset_buffer"), { desc = "reset file" } },
      { "v", call("preview_hunk_inline"), { desc = "preview hunk" } },
      { "b", call("blame_line", { full = true }), { desc = "blame line" } },
      { "d", call("diffthis"), { desc = "diff this" } },
      { "w", call("toggle_word_diff"), { desc = "word diff" } },
    },
    x = {
      { "s", on_selection("stage_hunk"), { desc = "stage lines" } },
      { "r", on_selection("reset_hunk"), { desc = "reset lines" } },
    },
  },
})
