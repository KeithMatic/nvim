local h = require("harness")

-- Markdown, as render-markdown draws it: loaded on the first Markdown file,
-- after the theme, so it's not preloaded here. Its groups then start as links
-- to ones that keep their background (DiffAdd, ColorColumn).

--- The background of `group`, following links.
local function bg(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false }).bg
end

local in_text = {
  "RenderMarkdownH1Bg",
  "RenderMarkdownH2Bg",
  "RenderMarkdownH3Bg",
  "RenderMarkdownH4Bg",
  "RenderMarkdownH5Bg",
  "RenderMarkdownH6Bg",
  "RenderMarkdownCode",
  "RenderMarkdownCodeBorder",
  "RenderMarkdownCodeInline",
}

h.test("heading bars, inline code and code blocks have no background", function()
  h.apply_theme("tokyonight-moon")
  h.eq(nil, package.loaded["render-markdown"], "render-markdown loaded before the Markdown file")
  local file = vim.fn.tempname() .. ".md"
  vim.fn.writefile({ "# Title", "", "## Section", "", "Some `code`.", "", "```sh", "ls", "```" }, file)
  vim.cmd.edit(file)
  local loaded = vim.wait(5000, function()
    return package.loaded["render-markdown"] ~= nil
  end, 50)
  h.eq(true, loaded, "render-markdown loaded")
  -- Loading fires LazyLoad, whose transparency pass is scheduled: let it run.
  vim.wait(200, function()
    return false
  end)
  local solid_groups = {}
  for _, group in ipairs(in_text) do
    if bg(group) then
      table.insert(solid_groups, ("%s (#%06x)"):format(group, bg(group)))
    end
  end
  h.eq({}, solid_groups, "groups with a background")
  -- The groups they linked to are left alone.
  h.eq(true, bg("DiffAdd") ~= nil, "DiffAdd keeps its background")
end)
