local h = require("harness")

local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
local toggle_file = vim.fn.stdpath("state") .. "/toggle-state.json"
local theme_file = vim.fn.stdpath("state") .. "/theme.json"

local function saved(path)
  return vim.fn.filereadable(path) == 1 and vim.fn.readfile(path, "b") or nil
end

local function restore(path, content)
  if content then
    vim.fn.writefile(content, path, "b")
  else
    vim.fn.delete(path)
  end
end

local function child(mode, toggles, theme)
  local toggle_before, theme_before = saved(toggle_file), saved(theme_file)
  vim.fn.mkdir(vim.fs.dirname(toggle_file), "p")
  if toggles then
    vim.fn.writefile({ vim.json.encode({ version = 1, toggles = toggles }) }, toggle_file)
  else
    vim.fn.delete(toggle_file)
  end
  if theme then
    vim.fn.writefile({ vim.json.encode(theme) }, theme_file)
  else
    vim.fn.delete(theme_file)
  end
  local result = vim
    .system({ "nvim", "--headless", "--cmd", "luafile " .. root .. "/tests/harness.lua" }, {
      env = {
        TEST_SPEC = root .. "/tests/toggles/boot.lua",
        TOGGLE_BOOT_MODE = mode,
      },
      text = true,
    })
    :wait(60000)
  restore(toggle_file, toggle_before)
  restore(theme_file, theme_before)
  require("toggle_state").reload()
  h.eq(0, result.code, "child boot:\n" .. (result.stdout or "") .. (result.stderr or ""))
end

h.test("a toggle saves its new state", function()
  local before = saved(toggle_file)
  require("toggle_state").reset()
  vim.o.showtabline = 2
  vim.api.nvim_feedkeys(vim.g.mapleader .. "uA", "mx", false)
  h.eq(0, vim.o.showtabline, "tabline toggled off")
  require("toggle_state").reload()
  h.eq(false, require("toggle_state").get("ui.tabline", true), "tabline saved")
  restore(toggle_file, before)
  require("toggle_state").reload()
end)

--- Run `fn` with no saved toggle state, then put back whatever was saved.
local function without_saved_toggles(fn)
  local before = saved(toggle_file)
  require("toggle_state").reset()
  local ok, err = pcall(fn)
  restore(toggle_file, before)
  require("toggle_state").reload()
  if not ok then
    error(err, 0)
  end
end

--- Edit a Lua file opened after boot, as from the Dashboard.
local function open_lua()
  local file = vim.fn.tempname() .. ".lua"
  vim.fn.writefile({ "local function greet(name)", "  return name", "end", "greet('hi')" }, file)
  vim.cmd.edit(file)
end

h.test("with nothing saved, a file opened after boot keeps Tree-sitter highlighting", function()
  without_saved_toggles(function()
    open_lua()
    vim.api.nvim_exec_autocmds("BufEnter", { buffer = 0 })
    h.eq(true, vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, "Tree-sitter active")
  end)
end)

h.test("with nothing saved, a file opened after boot keeps its inlay hints", function()
  without_saved_toggles(function()
    open_lua()
    local buf = vim.api.nvim_get_current_buf()
    h.eq(
      true,
      vim.wait(10000, function()
        return #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/inlayHint" }) > 0
      end, 50),
      "lua_ls attached"
    )
    vim.wait(200, function()
      return false
    end)
    h.eq(true, vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), "inlay hints enabled")
  end)
end)

h.test("<leader>uT in one buffer leaves Tree-sitter alone in another open buffer", function()
  without_saved_toggles(function()
    open_lua()
    local other = vim.api.nvim_get_current_buf()
    open_lua()
    vim.api.nvim_feedkeys(vim.g.mapleader .. "uT", "mx", false)
    h.eq(nil, vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "toggled off here")
    vim.api.nvim_set_current_buf(other)
    h.eq(true, vim.treesitter.highlighter.active[other] ~= nil, "still on in the other buffer")
  end)
end)

h.test("with nothing saved for the buffer, <leader>uf still turns formatting off in visited buffers", function()
  without_saved_toggles(function()
    open_lua()
    local visited = vim.api.nvim_get_current_buf()
    open_lua()
    vim.g.autoformat = true
    vim.api.nvim_feedkeys(vim.g.mapleader .. "uf", "mx", false)
    h.eq(false, LazyVim.format.enabled(visited), "formatting in the other visited buffer")
    vim.g.autoformat = true
  end)
end)

h.test("<leader>up saves Mini Pairs once mini.pairs has loaded", function()
  without_saved_toggles(function()
    require("lazy").load({ plugins = { "mini.pairs" } })
    vim.g.minipairs_disable = false
    vim.api.nvim_feedkeys(vim.g.mapleader .. "up", "mx", false)
    h.eq(true, vim.g.minipairs_disable, "pairs toggled off")
    require("toggle_state").reload()
    h.eq(false, require("toggle_state").get("editor.pairs", true), "pairs saved")
  end)
end)

h.test("a fresh process restores ordinary toggles and not temporary modes", function()
  child("saved", {
    ["diagnostics.enabled"] = false,
    ["editor.spell"] = true,
    ["editor.wrap"] = false,
    ["format.buffer"] = false,
    ["format.global"] = false,
    ["mode.dim"] = true,
    ["mode.profiler"] = true,
    ["mode.profiler_highlights"] = false,
    ["mode.zen"] = true,
    ["mode.zoom"] = true,
    ["editor.pairs"] = false,
    ["ui.animation"] = false,
    ["ui.dropbar"] = false,
    ["ui.indent_guides"] = false,
    ["ui.smooth_scroll"] = false,
    ["ui.tabline"] = false,
  })
end)

h.test("the statusline filename migrates from theme state", function()
  child("migration", nil, { statusline_filename = false, theme = "tokyonight-moon" })
  child("override", { ["ui.statusline_filename"] = true }, { statusline_filename = false, theme = "tokyonight-moon" })
end)
