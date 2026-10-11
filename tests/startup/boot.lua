-- Not a spec of its own: startup_spec.lua boots a second Neovim with this file
-- as its TEST_SPEC, once per Curated theme saved as the theme, to check that a
-- fresh start looks as applying that theme does.
local h = require("harness")

h.attach_ui(120, 40)

local theme = vim.env.EXPECT_THEME

h.test(theme .. ": starts as itself", function()
  -- Or as the variant it is: oasis is oasis-moonlight.
  local name = vim.g.colors_name
  h.eq(true, name == theme or vim.startswith(name, theme .. "-"), "started as " .. tostring(name))
end)

--- `group`'s definition, links followed. Not `link = false`, which follows the
--- current window's 'winhighlight' too (dropbar maps its icons to dimmed ones
--- in windows that aren't current).
---@param group string
---@return table
local function resolved(group)
  local hl = vim.api.nvim_get_hl(0, { name = group })
  for _ = 1, 20 do -- a theme could link in a loop
    if not hl.link then
      break
    end
    hl = vim.api.nvim_get_hl(0, { name = hl.link })
  end
  return hl
end

--- Every defined highlight group, links followed: what each one draws with.
--- Not `default`, which changes nothing drawn.
---@return table<string, table>
local function all_highlights()
  local groups = {}
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local hl = resolved(name)
    hl.default = nil
    if next(hl) then
      groups[name] = hl
    end
  end
  return groups
end

h.test(theme .. ": the statusline has no background after a fresh start", function()
  -- What it draws with, as evaluated: not the screen's cells, which lualine
  -- renumbers by defining highlights as it draws.
  local drawn = vim.api.nvim_eval_statusline(vim.o.statusline, { highlights = true })
  local solid = {}
  for _, part in ipairs(drawn.highlights) do
    for _, group in ipairs(part.groups or { part.group }) do
      local bg = resolved(group).bg
      if bg and not vim.list_contains(solid, group) then
        table.insert(solid, ("%s (#%06x)"):format(group, bg))
      end
    end
  end
  h.eq(0, #solid, "statusline groups with a background:\n" .. table.concat(solid, "\n"))
end)

--- `group`'s background, links followed, as "#rrggbb"; nil when it has none.
---@param group string
---@return string?
local function background(group)
  local bg = resolved(group).bg
  return bg and ("#%06x"):format(bg)
end

-- The accents a float keeps a background for, by name: the selected item (the
-- Tint), the cursor, search matches, scrollbars, signature help's active
-- parameter, the picker's window labels, noice's confirm buttons and progress
-- bar, and Lazy's and Mason's tab buttons and blocks.
local accents = {
  "Sel",
  "Cursor",
  "Visual",
  "Search",
  "Thumb",
  "Scrollbar",
  "ScrollBar",
  "ActiveParameter",
  "PickWin",
  "NoiceFormatConfirm",
  "NoiceFormatProgress",
  "LazyButton",
  "LazyH1",
  "MasonHeader",
  "MasonHighlightBlock",
  "MasonMutedBlock",
}

---@param group string
---@return boolean
local function accent(group)
  for _, part in ipairs(accents) do
    if group:find(part, 1, true) then
      return true
    end
  end
  return false
end

--- The Float sweep's check: every group the open windows draw with that has a
--- background and isn't an accent, as "filetype: group (#rrggbb)". A window
--- draws with what its 'winhighlight' maps the window groups to (a float's
--- Normal falls back to NormalFloat), its title's and footer's groups, and what
--- its text and virtual text are highlighted with. Splits too: the Runner's
--- terminal, noice's split for long messages.
---@return string[]
local function solid_in_windows()
  local found = {}
  local function check(win, group)
    if type(group) == "string" and group ~= "" and not accent(group) and background(group) then
      local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      found[("%s: %s (%s)"):format(filetype, group, background(group))] = true
    end
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    local float = config.relative ~= ""
    local map = {}
    for from, to in vim.wo[win].winhighlight:gmatch("([^:,]+):([^,]*)") do
      map[from] = to
    end
    local groups = float and { "NormalFloat", "FloatBorder", "FloatTitle", "FloatFooter" } or { "NormalNC" }
    for _, group in ipairs(groups) do
      check(win, map[group] or group)
    end
    check(win, map.Normal or (float and (map.NormalFloat or "NormalFloat")) or "Normal")
    for _, chunk in ipairs(vim.list_extend(vim.deepcopy(config.title or {}), config.footer or {})) do
      check(win, chunk[2])
    end
    local buf = vim.api.nvim_win_get_buf(win)
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
      local details = mark[4]
      for _, key in ipairs({ "hl_group", "line_hl_group", "sign_hl_group", "number_hl_group" }) do
        check(win, details[key])
      end
      local chunks = vim.deepcopy(details.virt_text or {})
      for _, line in ipairs(details.virt_lines or {}) do
        vim.list_extend(chunks, line)
      end
      for _, chunk in ipairs(chunks) do
        for _, group in ipairs(type(chunk[2]) == "table" and chunk[2] or { chunk[2] }) do
          check(win, group)
        end
      end
    end
  end
  local list = vim.tbl_keys(found)
  table.sort(list)
  return list
end

--- Whether noice shows the cmdline of type `type` (":", "/", "@" for input()),
--- with its icon when the format has one (drawn as virtual text).
---@param type string
---@param icon boolean
local function cmdline_shown(type, icon)
  local pos = require("noice").api.get_cmdline_position()
  if vim.fn.getcmdtype() ~= type or not (pos and vim.api.nvim_win_is_valid(pos.win)) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(pos.win)
  return not icon or #vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { type = "virt_text" }) > 0
end

-- The cmdline in each format noice shows, by the keys that open it; input()
-- through a command that asks for it, with no icon.
local cmdline_formats = {
  { name = "command", keys = ":", type = ":" },
  { name = "search", keys = "/", type = "/" },
  { name = "backward search", keys = "?", type = "?" },
  { name = "filter (shell)", keys = ":!", type = ":" },
  { name = "Lua", keys = ":lua ", type = ":" },
  { name = "help", keys = ":help ", type = ":" },
  { name = "input()", keys = ":lua vim.fn.input('Name: ')<CR>", type = "@", no_icon = true },
}

for _, format in ipairs(cmdline_formats) do
  h.test(theme .. ": the " .. format.name .. " cmdline draws nothing on a background", function()
    local solid
    h.drive(format.keys, {
      function()
        if not cmdline_shown(format.type, not format.no_icon) then
          return false
        end
        solid = solid_in_windows()
      end,
    })
    assert(solid, "the cmdline never showed")
    h.eq(0, #solid, "groups with a background:\n" .. table.concat(solid, "\n"))
  end)
end

--- A window whose buffer shows `text`, else false.
---@param text string
---@return integer|false
local function window_showing(text)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
    if table.concat(lines, "\n"):find(text, 1, true) then
      return win
    end
  end
  return false
end

--- A window whose buffer has filetype `filetype`, else false.
---@param filetype string
---@return integer|false
local function window_of(filetype)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == filetype then
      return win
    end
  end
  return false
end

--- The open floats but the Buffer sticks', which are always there.
---@return integer[]
local function floats_open()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
      and vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "buffersticks"
  end, vim.api.nvim_list_wins())
end

--- Close every float but the Buffer sticks', and every split but the first.
local function close_windows()
  for _, win in ipairs(floats_open()) do
    pcall(vim.api.nvim_win_close, win, true)
  end
  h.close_splits()
end

--- Open a float with `open`, and once `ready` returns something other than
--- false, run the Float sweep's check and close it with `close`. `open` may
--- wait for a key (the Buffer list, the confirm): the check runs from a timer.
---@param open fun()
---@param ready fun(): any
---@param close? fun() default: close_windows
---@return string[] solid
local function sweep(open, ready, close)
  close = close or close_windows
  local solid, outcome
  local deadline = vim.uv.now() + 8000
  local timer = assert(vim.uv.new_timer())
  timer:start(
    50,
    50,
    vim.schedule_wrap(function()
      if outcome then
        return
      end
      local ok, shown = pcall(ready)
      if ok and shown ~= false and shown ~= nil then
        solid, outcome = solid_in_windows(), "checked"
      elseif vim.uv.now() > deadline then
        outcome = ok and "it never showed" or ("its check failed: " .. tostring(shown))
      end
      if outcome then
        timer:stop()
        timer:close()
        close()
      end
    end)
  )
  open()
  vim.wait(10000, function()
    return outcome ~= nil
  end, 20)
  assert(outcome == "checked", outcome or "it never showed")
  vim.wait(100, function()
    return false
  end)
  return solid
end

-- A language server in this Neovim, for hover, signature help, LSP progress and
-- completion docs: `greet`, documented.
local lsp_progress
local function fake_server(dispatchers)
  local closing = false
  local results = {
    initialize = {
      capabilities = {
        hoverProvider = true,
        signatureHelpProvider = { triggerCharacters = { "(" } },
        completionProvider = {},
      },
    },
    ["textDocument/hover"] = {
      contents = { kind = "markdown", value = "```lua\nfunction greet(name: string)\n```\nSays hello." },
    },
    ["textDocument/signatureHelp"] = {
      signatures = { { label = "greet(name: string)", parameters = { { label = "name: string" } } } },
      activeSignature = 0,
      activeParameter = 0,
    },
    ["textDocument/completion"] = {
      isIncomplete = false,
      items = { { label = "greeting", kind = 6, documentation = { kind = "markdown", value = "A **greeting**." } } },
    },
  }
  lsp_progress = function(kind, title)
    dispatchers.notification("$/progress", { token = "sweep", value = { kind = kind, title = title, percentage = 40 } })
  end
  local id = 0
  return {
    request = function(method, _, callback)
      id = id + 1
      vim.schedule(function()
        callback(nil, results[method])
      end)
      return true, id
    end,
    notify = function(method)
      closing = closing or method == "exit"
      return true
    end,
    is_closing = function()
      return closing
    end,
    terminate = function()
      closing = true
    end,
  }
end

--- A Lua buffer with the fake language server attached, in the current window.
local function lsp_buffer()
  vim.cmd.enew({ bang = true })
  vim.bo.filetype = "lua"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "greet(" })
  local client = vim.lsp.start({ name = "sweep", cmd = fake_server, root_dir = vim.fn.getcwd() })
  vim.wait(3000, function()
    return client ~= nil and vim.lsp.get_client_by_id(client).initialized
  end, 20)
  vim.api.nvim_win_set_cursor(0, { 1, 1 })
end

-- The rest of the floats the config shows, each opened as a user would, in turn.
local floats = {
  {
    name = "notifications at every level",
    open = function()
      for _, level in ipairs({ "TRACE", "DEBUG", "INFO", "WARN", "ERROR" }) do
        vim.notify("sweep " .. level, vim.log.levels[level])
      end
    end,
    ready = function()
      return window_showing("sweep TRACE") and window_showing("sweep ERROR")
    end,
    close = function()
      Snacks.notifier.hide()
    end,
  },
  {
    name = "the notification history",
    open = function()
      Snacks.notifier.show_history()
    end,
    ready = function()
      return window_of("snacks_notif_history")
    end,
  },
  {
    name = "LSP hover",
    open = function()
      lsp_buffer()
      vim.lsp.buf.hover()
    end,
    ready = function()
      return window_showing("Says hello")
    end,
  },
  {
    name = "signature help",
    open = function()
      lsp_buffer()
      vim.lsp.buf.signature_help()
    end,
    ready = function()
      return window_showing("greet(name: string)")
    end,
  },
  {
    name = "LSP progress",
    open = function()
      lsp_buffer()
      lsp_progress("begin", "Sweeping")
    end,
    ready = function()
      return window_showing("Sweeping")
    end,
    close = function()
      lsp_progress("end", "Sweeping")
      close_windows()
    end,
  },
  {
    name = "the confirm dialog",
    open = function()
      vim.fn.confirm("Sweep?", "&Yes\n&No")
    end,
    ready = function()
      return window_showing("Sweep?")
    end,
    close = function()
      vim.api.nvim_input("<Esc>")
    end,
  },
  {
    name = "the last message in a popup",
    open = function()
      vim.cmd.echomsg('"sweep message"')
      vim.cmd("Noice last")
    end,
    ready = function()
      return window_showing("sweep message")
    end,
  },
  {
    name = "a long message, in a split",
    open = function()
      vim.cmd.echo(vim.fn.string(("sweep line\n"):rep(25)))
    end,
    ready = function()
      return window_showing("sweep line")
    end,
  },
  {
    name = "which-key",
    open = function()
      require("which-key").show({ keys = "<leader>" })
    end,
    ready = function()
      return window_of("wk")
    end,
    close = function()
      vim.api.nvim_input("<Esc>")
      close_windows()
    end,
  },
  {
    name = "Lazy",
    open = function()
      vim.cmd("Lazy")
    end,
    ready = function()
      return window_of("lazy")
    end,
  },
  {
    name = "Mason",
    open = function()
      vim.cmd("Mason")
    end,
    ready = function()
      return window_of("mason")
    end,
  },
  {
    name = "the picker",
    open = function()
      Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
    end,
    ready = function()
      local picker = Snacks.picker.get({ source = "files" })[1]
      return picker and #picker:items() > 0 and window_of("snacks_picker_list")
    end,
    close = function()
      for _, picker in ipairs(Snacks.picker.get({ source = "files" })) do
        picker:close()
      end
    end,
  },
  {
    name = "Snacks' input",
    open = function()
      Snacks.input({ prompt = "Sweep" }, function() end)
    end,
    ready = function()
      return window_of("snacks_input")
    end,
    close = function()
      vim.cmd.stopinsert()
      close_windows()
    end,
  },
  {
    name = "the Explorer",
    open = function()
      h.focus_explorer()
    end,
    ready = function()
      return window_of("neo-tree")
    end,
    close = function()
      vim.cmd("Neotree close")
    end,
  },
  {
    name = "the Terminal manager",
    open = function()
      require("terminal").toggle()
    end,
    ready = function()
      return require("terminal").shown()
    end,
    close = function()
      require("terminal").toggle()
      vim.cmd.stopinsert()
    end,
  },
  {
    name = "the Buffer list",
    open = function()
      require("column_order").pick("split")
    end,
    ready = function()
      return window_of("buffersticks") and BufferSticks.is_visible()
    end,
    close = function()
      vim.api.nvim_input("<Esc>")
    end,
  },
  {
    name = "a Habit tip",
    open = function()
      local cmd = next(require("tobira.i18n").load().suggestions)
      require("tobira.ui.float").show({ cmd = cmd, category = "motion" }, false)
    end,
    ready = function()
      return require("tobira.ui.float").is_open()
    end,
    close = function()
      require("tobira.ui.float").close()
    end,
  },
  {
    name = "the Habit tips' guide, progress and stats",
    open = function()
      require("tobira.ui.guide").open()
    end,
    ready = function()
      return require("tobira.ui.guide").is_open()
    end,
  },
  {
    name = "the cheat sheet",
    open = function()
      h.feed("<leader>sK", "mx")
    end,
    ready = function()
      return #floats_open() > 0
    end,
  },
  {
    name = "the Runner",
    open = function()
      local file = vim.fn.tempname() .. ".py"
      vim.fn.writefile({ "print('sweep run')" }, file)
      vim.cmd.edit(file)
      require("runner").run()
    end,
    ready = function()
      return window_showing("sweep run")
    end,
    close = function()
      vim.cmd.stopinsert()
      close_windows()
    end,
  },
}

-- blink's menu shows while typing, so it's typed rather than opened.
h.test(theme .. ": blink's menu and docs draw nothing on a background", function()
  lsp_buffer()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
  local solid
  h.drive("i", {
    "gre",
    function()
      if not (window_of("blink-cmp-menu") and window_of("blink-cmp-documentation")) then
        return false
      end
      solid = solid_in_windows()
    end,
  })
  close_windows()
  assert(solid, "blink's menu and docs never showed")
  h.eq(0, #solid, "groups with a background:\n" .. table.concat(solid, "\n"))
end)

for _, float in ipairs(floats) do
  h.test(theme .. ": " .. float.name .. " draw nothing on a background", function()
    local solid = sweep(float.open, float.ready, float.close)
    h.eq(0, #solid, "groups with a background:\n" .. table.concat(solid, "\n"))
  end)
end

--- Whether the comparison leaves `group` out: groups set by something other
--- than the theme, which a theme change doesn't redo: the cursors, which modes.nvim colours in each mode (themes link
--- CursorIM, lCursor, noice's and hop's to Cursor), which-key's icons, linked to
--- mini.icons' colours only as which-key loads, lualine's groups but its
--- sections' in normal mode (a mode's, or a component's, are brought up to date
--- only when they're drawn), and Vim's syntax files' (pythonBoolean), which
--- treesitter's highlighting replaces.
---@param group string
---@return boolean
local function not_compared(group)
  return group == "CursorIM"
    or group:match("Cursor$") ~= nil
    or group:match("^WhichKeyIcon") ~= nil
    or (group:match("^lualine_") ~= nil and not group:match("^lualine_%a_normal$"))
    or group:match("^%l") ~= nil
end

h.test(theme .. ": with every plugin loaded, it looks as when the theme is applied again", function()
  local unloaded = {}
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    if not plugin._.loaded then
      table.insert(unloaded, name)
    end
  end
  require("lazy").load({ plugins = unloaded })
  vim.wait(200, function()
    return false
  end)
  local startup = all_highlights()
  h.apply_theme(theme)
  local again = all_highlights()

  -- Groups only one side defines are the plugin's doing, not the look's: some
  -- define theirs on first use (blink), some don't define them again after a
  -- theme change (aerial, lspsaga, crates).
  local differ = {}
  for name in pairs(again) do
    if startup[name] and not not_compared(name) and not vim.deep_equal(startup[name], again[name]) then
      table.insert(
        differ,
        ("%s: %s, applied again %s"):format(
          name,
          vim.inspect(startup[name], { newline = " ", indent = "" }),
          vim.inspect(again[name], { newline = " ", indent = "" })
        )
      )
    end
  end
  table.sort(differ)
  h.eq(0, #differ, "groups that differ from applying the theme again:\n" .. table.concat(differ, "\n"))
end)
