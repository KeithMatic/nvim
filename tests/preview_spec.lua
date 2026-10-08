local h = require("harness")

-- The Browser group (<leader>v): the Markdown preview (mdkite) and the Live
-- server (kitehost), loaded on their key or command, never at startup.

h.test("markdown-preview.nvim is disabled", function()
  local spec = require("lazy.core.config").spec
  h.eq(true, spec.disabled["markdown-preview.nvim"] ~= nil, "markdown-preview.nvim among lazy's disabled plugins")
  h.eq(nil, spec.plugins["markdown-preview.nvim"], "markdown-preview.nvim among lazy's plugins")
end)

h.test("neither plugin loads at startup", function()
  h.eq(nil, package.loaded["mdkite"], "mdkite loaded")
  h.eq(nil, package.loaded["kitehost"], "kitehost loaded")
end)

h.test(":MdKite and :KiteHost exist", function()
  h.eq(2, vim.fn.exists(":MdKite"), ":MdKite command")
  h.eq(2, vim.fn.exists(":KiteHost"), ":KiteHost command")
end)

h.test("<leader>v is the browser group in which-key", function()
  local leader = vim.g.mapleader
  local groups = vim
    .iter(require("which-key.config").mappings)
    :filter(function(m)
      return m.group and vim.keycode(m.lhs) == leader .. "v"
    end)
    :map(function(m)
      return m.desc
    end)
    :totable()
  h.eq({ "browser" }, groups, "which-key groups on <leader>v")
end)

h.test("<leader>v keys drive the Live server", function()
  local leader = vim.g.mapleader
  for key, desc in pairs({
    s = "Start Live Server",
    x = "Stop Live Server",
    X = "Stop All Live Servers",
    i = "Live Server Status",
  }) do
    h.eq(desc, vim.fn.maparg(leader .. "v" .. key, "n", false, true).desc, "<leader>v" .. key)
  end
end)

h.test("<leader>vm and <leader>cp toggle the Markdown preview in a Markdown buffer", function()
  local leader = vim.g.mapleader
  h.open("md")
  -- Until mdkite loads, the buffer holds lazy's stub, which runs the key's rhs
  -- from the plugin's keys handler: check both.
  local handler = require("lazy.core.config").plugins["mdkite.nvim"]._.handlers.keys
  for _, lhs in ipairs({ "vm", "cp" }) do
    local mapping = vim.fn.maparg(leader .. lhs, "n", false, true)
    h.eq("Toggle Markdown Preview", mapping.desc, "<leader>" .. lhs)
    h.eq(1, mapping.buffer, "<leader>" .. lhs .. " is buffer-local")
    local key = handler[(" %s (markdown)"):format(lhs)]
    h.eq("<cmd>MdKite toggle<cr>", key and key.rhs, "<leader>" .. lhs .. " runs")
  end
end)

h.test("<leader>vm and <leader>cp aren't set outside Markdown", function()
  local leader = vim.g.mapleader
  h.open("lua")
  for _, lhs in ipairs({ "vm", "cp" }) do
    h.eq("", vim.fn.maparg(leader .. lhs, "n"), "<leader>" .. lhs .. " in a Lua buffer")
  end
end)
