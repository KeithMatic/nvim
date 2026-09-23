local h = require("harness")

local icons = require("util.icons")

h.attach_ui(120, 40)

--- Run `fn` with a files picker once it shows more than one item, then close
--- it and wait until it's gone (opening a source that's still open toggles it
--- shut instead), whether `fn` passed or not.
---@param fn fun(picker: snacks.Picker)
---@param opts? snacks.picker.files.Config
local function with_files(fn, opts)
  local picker = Snacks.picker.files(vim.tbl_extend("force", { cwd = vim.fn.stdpath("config") }, opts or {}))
  local ok, err = pcall(function()
    local shown = vim.wait(5000, function()
      return picker.list.win:valid() and picker:count() > 1 and not picker:is_active()
    end, 20)
    h.eq(true, shown, "the files picker shows its items")
    vim.cmd.redraw()
    fn(picker)
  end)
  picker:close()
  vim.wait(1000, function()
    return #Snacks.picker.get({ source = "files" }) == 0
  end, 10)
  if not ok then
    error(err, 0)
  end
end

--- The screen text at `row` (1-indexed) from the left edge of `win`, `width` cells long.
local function screen_text(win, row, width)
  local col = vim.fn.win_screenpos(win)[2]
  local cells = {}
  for c = col, col + width - 1 do
    table.insert(cells, vim.fn.screenstring(row, c))
  end
  return table.concat(cells)
end

--- The screen row (1-indexed) `win` shows its cursor on.
local function cursor_row(win)
  return vim.fn.win_screenpos(win)[1] + vim.api.nvim_win_call(win, vim.fn.winline) - 1
end

local pointer = icons.misc.selection_caret
local width = vim.api.nvim_strwidth(pointer)

h.test("the picker's prompt is the Icon set's prompt glyph", function()
  with_files(function(picker)
    local win = picker.input.win.win
    local row = vim.fn.win_screenpos(win)[1]
    h.eq(icons.misc.prompt_prefix, screen_text(win, row, vim.api.nvim_strwidth(icons.misc.prompt_prefix)))
  end)
end)

h.test("the list's cursor row shows the Icon set's pointer, other rows don't", function()
  with_files(function(picker)
    local win = picker.list.win.win
    local cursor = cursor_row(win)
    local top = vim.fn.win_screenpos(win)[1]
    local bottom = top + vim.api.nvim_win_get_height(win) - 1
    for row = top, bottom do
      h.eq(row == cursor and pointer or (" "):rep(width), screen_text(win, row, width), ("screen row %d"):format(row))
    end

    -- It follows the cursor.
    picker.list:move(1)
    vim.cmd.redraw()
    local moved = cursor_row(win)
    h.eq(true, moved ~= cursor, "the cursor moved")
    h.eq(pointer, screen_text(win, moved, width), "pointer on the new cursor row")
    h.eq((" "):rep(width), screen_text(win, cursor, width), "no pointer on the old cursor row")
  end)
end)

h.test("the pointer is drawn in the cursor line's background", function()
  with_files(function(picker)
    local win = picker.list.win.win
    local function bg(group)
      return vim.api.nvim_get_hl(0, { name = group, link = false }).bg
    end
    local function pointer_bg()
      local lnum = vim.api.nvim_win_get_cursor(win)[1]
      local column = vim.api.nvim_eval_statusline(vim.wo[win].statuscolumn, {
        winid = win,
        use_statuscol_lnum = lnum,
        highlights = true,
      })
      h.eq(pointer, column.str, "the cursor row's column")
      return bg(column.highlights[1].group)
    end
    local line_group = vim.wo[win].winhighlight:match("%f[%w]CursorLine:([%w_]+)")
    h.eq("SnacksPickerListCursorLine", line_group, "Snacks's focused cursor line")
    h.eq(bg(line_group), pointer_bg(), "focused")

    -- Snacks gives the list the plain CursorLine when the picker has lost
    -- focus (only a picker that stays open when left can), on its next render.
    vim.cmd.wincmd("p")
    picker.list:update_cursorline()
    h.eq("CursorLine", vim.wo[win].winhighlight:match("%f[%w]CursorLine:([%w_]+)"), "Snacks's unfocused cursor line")
    h.eq(bg("CursorLine"), pointer_bg(), "unfocused")
  end, { auto_close = false })
end)
