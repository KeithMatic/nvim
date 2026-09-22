local h = require("harness")

h.test("runs inside the XDG sandbox, not the real Neovim directories", function()
  local sandbox = vim.fs.dirname(vim.env.XDG_DATA_HOME)
  for _, what in ipairs({ "config", "data", "state", "cache" }) do
    local path = vim.fn.stdpath(what) --[[@as string]]
    h.eq(sandbox, path:sub(1, #sandbox), what .. " dir " .. path)
  end
end)

h.test("loads LazyVim", function()
  h.eq(true, package.loaded.lazyvim ~= nil or _G.LazyVim ~= nil, "LazyVim loaded")
end)

h.test("boots with no errors or error notifications", function()
  h.eq({}, h.errors())
end)
