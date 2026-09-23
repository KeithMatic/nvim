local h = require("harness")

local references = { "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }

--- The reference groups that have a background, are reversed or aren't underlined.
local function misstyled_references()
  local misstyled = {}
  for _, name in ipairs(references) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl.bg or hl.ctermbg or hl.reverse or not hl.underline then
      table.insert(misstyled, ("%s %s"):format(name, vim.inspect(hl, { newline = "", indent = "" })))
    end
  end
  return misstyled
end

for _, theme in ipairs(require("theme").themes) do
  h.test(theme .. ": reference highlights are underlines with no background", function()
    h.apply_theme(theme)
    h.eq({}, misstyled_references(), "reference groups")
  end)
end

h.test("reference highlights stay underlines with no background after switching theme", function()
  h.apply_theme("tokyonight-moon")
  h.apply_theme("catppuccin-mocha")
  h.eq({}, misstyled_references(), "after switching to catppuccin-mocha")
  h.apply_theme("tokyonight-storm")
  h.eq({}, misstyled_references(), "after switching to tokyonight-storm")
end)
