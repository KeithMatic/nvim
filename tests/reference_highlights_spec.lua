local h = require("harness")

local references = { "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }

--- Apply `theme` and let the scheduled transparency pass run.
local function apply(theme)
  vim.cmd.colorscheme(theme)
  vim.wait(200, function()
    return false
  end)
end

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
    apply(theme)
    h.eq({}, misstyled_references(), "reference groups")
  end)
end

h.test("reference highlights stay underlines with no background after switching theme", function()
  apply("tokyonight-moon")
  apply("catppuccin-mocha")
  h.eq({}, misstyled_references(), "after switching to catppuccin-mocha")
  apply("tokyonight-storm")
  h.eq({}, misstyled_references(), "after switching to tokyonight-storm")
end)
