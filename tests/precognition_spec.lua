local h = require("harness")

local lhs = vim.g.mapleader .. "uP"

--- The number of motion hints precognition has drawn in the current buffer.
local function hint_count()
  local ns = vim.api.nvim_get_namespaces().precognition
  return ns and #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) or 0
end

--- Wait briefly for the hints to be drawn (`expected` true) or cleared (false),
--- then return whether any are shown.
local function hints_shown_after_waiting(expected)
  vim.wait(500, function()
    return (hint_count() > 0) == expected
  end, 20)
  return hint_count() > 0
end

--- Open a scratch buffer with a line that has motion targets, cursor mid-line.
local function open_text()
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local answer = compute(first, second) + 42", "return answer" })
  vim.api.nvim_win_set_cursor(0, { 1, 6 })
  vim.api.nvim_exec_autocmds("CursorMoved", {})
end

--- Press <leader>uP, then move the cursor as a user would to trigger a redraw.
local function press_toggle()
  vim.api.nvim_feedkeys(lhs, "mx", false)
  vim.api.nvim_exec_autocmds("CursorMoved", {})
end

h.test("<leader>uP has exactly one normal-mode mapping", function()
  local maps = vim.tbl_filter(function(m)
    return m.lhs == lhs
  end, vim.api.nvim_get_keymap("n"))
  h.eq(1, #maps, "global normal mappings on <leader>uP: " .. vim.inspect(maps))
end)

h.test("motion hints are hidden after boot", function()
  open_text()
  h.eq(false, hints_shown_after_waiting(false), "hints after boot")
end)

h.test("<leader>uP shows the hints, and pressing it again hides them", function()
  open_text()
  press_toggle()
  h.eq(true, hints_shown_after_waiting(true), "hints after the first <leader>uP")
  press_toggle()
  h.eq(false, hints_shown_after_waiting(false), "hints after the second <leader>uP")
end)

h.test("hints keep their highlight after being hidden and switching theme", function()
  open_text()
  press_toggle()
  press_toggle()
  h.apply_theme("catppuccin-mocha")
  h.eq(false, vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = "PrecognitionHighlight" })), "PrecognitionHighlight defined")
end)
