local h = require("harness")
local theme = require("theme")

-- Habit tips (tobira): a tip's border takes its category's colour, but only
-- as the line's colour, never a solid band round the glass.

-- The categories' border groups (tobira's ui/float.lua CATEGORY_HL).
local borders = {
  "TobiraSuggestMotion",
  "TobiraSuggestEdit",
  "TobiraSuggestSearch",
  "TobiraSuggestWindow",
  "TobiraSuggestFold",
  "TobiraSuggestMark",
  "TobiraSuggestMacro",
  "TobiraSuggestDiff",
  "TobiraSuggestEx",
  "TobiraSuggestTerminal",
}

for _, name in ipairs({ "tokyonight-moon", "catppuccin-mocha" }) do
  h.test(name .. ": every tip border is a coloured line with no background", function()
    h.with_state(nil, function()
      h.apply_theme(name)
      -- tobira sets its colours again each time it draws a tip.
      require("tobira.ui.hls").setup()
      for _, group in ipairs(borders) do
        local hl = theme.get_hl(group)
        h.eq(nil, hl.bg, group .. " background")
        h.eq(true, hl.fg ~= nil, group .. " has a colour")
      end
    end)
  end)
end
