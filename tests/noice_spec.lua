local h = require("harness")

local icons = require("util.icons")

h.attach_ui(120, 40)

--- The window noice shows the cmdline's text in, once it's shown.
local function cmdline_win()
  local pos = require("noice").api.get_cmdline_position()
  return pos and vim.api.nvim_win_is_valid(pos.win) and pos.win or false
end

--- The screen rows and columns (0-indexed, end exclusive) the cmdline popup
--- covers, border included: noice draws the border as a window of its own,
--- which the text's window sits in.
local function popup_frame()
  local win = assert(cmdline_win(), "no cmdline shown")
  local config = vim.api.nvim_win_get_config(win)
  local frame = config.relative == "win" and config.win or win
  local row, col = unpack(vim.api.nvim_win_get_position(frame))
  local frame_config = vim.api.nvim_win_get_config(frame)
  return { top = row, bottom = row + frame_config.height, left = col, right = col + frame_config.width }
end

--- blink's completion menu window, once it's shown.
local function menu_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if
      vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "blink-cmp-menu" and require("blink.cmp").is_menu_visible()
    then
      return win
    end
  end
  return false
end

--- The icon noice shows before the cmdline's text.
local function cmdline_icon()
  local buf = vim.api.nvim_win_get_buf((assert(cmdline_win(), "no cmdline shown")))
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
    local virt_text = mark[4].virt_text
    if virt_text and virt_text[1][1]:find("%S") then
      return virt_text[1][1]
    end
  end
end

for _, size in ipairs({ { 120, 40 }, { 90, 25 } }) do
  local width, height = unpack(size)
  h.test(("the cmdline popup is centred on a %dx%d screen"):format(width, height), function()
    vim.o.columns, vim.o.lines = width, height
    local frame
    h.drive(":", {
      cmdline_win,
      function()
        frame = popup_frame()
      end,
    })
    local margins = {
      top = frame.top,
      bottom = vim.o.lines - frame.bottom,
      left = frame.left,
      right = vim.o.columns - frame.right,
    }
    -- An odd leftover row or column can't be split: one side gets it.
    h.eq(true, math.abs(margins.top - margins.bottom) <= 1, "top and bottom margins: " .. vim.inspect(margins))
    h.eq(true, math.abs(margins.left - margins.right) <= 1, "left and right margins: " .. vim.inspect(margins))
  end)
end

h.test("the cmdline's completion menu opens one row below the popup's bottom border", function()
  vim.o.columns, vim.o.lines = 120, 40
  local frame, menu_top
  -- Typed once the cmdline is open: blink loads on entering it.
  h.drive(":", {
    cmdline_win,
    "e ",
    menu_win,
    function()
      frame = popup_frame()
      menu_top = vim.api.nvim_win_get_position(menu_win())[1]
    end,
  })
  -- frame.bottom is the row just past the border: the first free row.
  h.eq(frame.bottom, menu_top, "menu's top row (popup rows " .. frame.top .. "-" .. frame.bottom - 1 .. ")")
end)

h.test("the search cmdline's completion menu leaves the typed text visible", function()
  vim.o.columns, vim.o.lines = 120, 40
  vim.cmd.enew({ bang = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "helloworld hellothere" })
  local text_row, menu_rows
  -- Search's menu only opens on <Tab>. LazyVim puts search at the bottom, so
  -- the menu opens above it.
  h.drive("/", {
    cmdline_win,
    "hel",
    "<Tab>",
    menu_win,
    function()
      text_row = vim.api.nvim_win_get_position(cmdline_win())[1]
      local menu = menu_win()
      local top = vim.api.nvim_win_get_position(menu)[1]
      menu_rows = { top, top + vim.api.nvim_win_get_config(menu).height + 1 } -- + its border
    end,
  })
  h.eq(
    true,
    text_row < menu_rows[1] or text_row > menu_rows[2],
    ("text on row %d, menu on rows %d-%d"):format(text_row, menu_rows[1], menu_rows[2])
  )
end)

-- noice puts its own space after the icon.
local formats = {
  { name = "command", keys = ":", icon = vim.trim(icons.misc.Vim) },
  { name = "search", keys = "/", icon = vim.trim(icons.ui.Search) .. " " .. icons.ui.ChevronShortDown },
  { name = "backward search", keys = "?", icon = vim.trim(icons.ui.Search) .. " " .. icons.ui.ChevronShortUp },
  { name = "Lua", keys = ":lua ", icon = icons.misc.lua },
  { name = "help", keys = ":help ", icon = vim.trim(icons.diagnostics.Question) },
  { name = "filter (shell)", keys = ":!", icon = vim.trim(icons.ui.Terminal) },
}
for _, format in ipairs(formats) do
  h.test(("the %s cmdline shows the Icon set's glyph"):format(format.name), function()
    local icon
    h.drive(format.keys, {
      function()
        icon = cmdline_win() and cmdline_icon()
        return icon ~= nil and icon
      end,
    })
    h.eq(format.icon, icon, format.name .. " icon")
  end)
end
