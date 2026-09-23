local h = require("harness")

--- A fresh scratch buffer holding `lines`, cursor on the first line, unmodified.
local function scratch(lines)
  vim.cmd.enew({ bang = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modified = false
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

--- Type `keys` from normal mode, as if typed, and return the mode and the
--- cursor ({row, col}) right after them, before anything else ends the mode.
local function type_keys(keys)
  local mode, cursor
  _G.better_escape_spec_capture = function()
    mode = vim.fn.mode()
    cursor = vim.api.nvim_win_get_cursor(0)
  end
  h.feed(keys .. "<Cmd>lua better_escape_spec_capture()<CR><Esc>", "xt")
  return mode, cursor
end

--- The current buffer's lines.
local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

for _, seq in ipairs({ "jk", "jj" }) do
  h.test(("%s in insert mode returns to normal mode, leaving neither letter"):format(seq), function()
    scratch({ "" })
    h.eq("n", (type_keys("ifoo" .. seq)), "mode after " .. seq)
    h.eq({ "foo" }, lines(), "buffer")
  end)

  h.test(("%s alone in an unmodified buffer leaves it unmodified"):format(seq), function()
    scratch({ "" })
    h.eq("n", (type_keys("i" .. seq)), "mode after " .. seq)
    h.eq({ "" }, lines(), "buffer")
    h.eq(false, vim.bo.modified, "buffer modified")
  end)

  h.test(("%s in the cmdline leaves the cmdline without running it"):format(seq), function()
    scratch({ "" })
    vim.g.better_escape_spec_ran = nil
    h.eq("n", (type_keys(":let g:better_escape_spec_ran = 1" .. seq)), "mode after " .. seq)
    h.eq(nil, vim.g.better_escape_spec_ran, "command not run")
  end)
end

h.test("ja in insert mode inserts ja", function()
  scratch({ "" })
  h.eq("i", (type_keys("ija")), "mode after ja")
  h.eq({ "ja" }, lines(), "buffer")
end)

h.test("a j that times out is kept, and a later k is typed", function()
  scratch({ "" })
  local since, mode, typed
  h.drive("i", {
    "j",
    function()
      since = since or vim.uv.now()
      return vim.uv.now() - since > 300 -- past the 200 ms window
    end,
    "k",
    function()
      mode, typed = vim.fn.mode(), lines()
    end,
  })
  h.eq("i", mode, "mode after a slow jk")
  h.eq({ "jk" }, typed, "buffer")
end)

h.test("jj in visual mode moves the cursor two lines", function()
  scratch({ "1", "2", "3", "4" })
  local mode, cursor = type_keys("vjj")
  h.eq("v", mode, "mode after vjj")
  h.eq({ 3, 0 }, cursor, "cursor")
end)

-- A claim about which modes are mapped: terminal and select mode keep j/k.
h.test("j and k are not mapped in terminal or select mode", function()
  for _, mode in ipairs({ "t", "s" }) do
    for _, key in ipairs({ "j", "k" }) do
      h.eq("", vim.fn.maparg(key, mode), ("%s-mode %s mapping"):format(mode, key))
    end
  end
end)
