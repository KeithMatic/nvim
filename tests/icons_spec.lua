local h = require("harness")

local root = vim.fs.dirname(vim.fs.dirname(vim.env.TEST_SPEC))
local icons = require("util.icons")

h.test("LazyVim's icon options hold the Icon set's kinds", function()
  local kinds = LazyVim.config.icons.kinds
  h.eq("\u{ea8c} ", kinds.Function, "kinds.Function")
  h.eq("\u{f024b} ", kinds.Folder, "kinds.Folder")
  h.eq("\u{ea8b} ", kinds.Module, "kinds.Module")
  -- Kinds the Icon set doesn't define keep LazyVim's glyph.
  h.eq(true, kinds.Copilot ~= nil, "kinds.Copilot kept")
end)

h.test("LazyVim's icon options hold the Icon set's diagnostics", function()
  local diagnostics = LazyVim.config.icons.diagnostics
  h.eq("\u{ea87} ", diagnostics.Error, "diagnostics.Error")
  h.eq("\u{ea6c} ", diagnostics.Warn, "diagnostics.Warn")
  h.eq("\u{f0336} ", diagnostics.Hint, "diagnostics.Hint")
end)

h.test("LazyVim's icon options hold the Icon set's git signs", function()
  local git = LazyVim.config.icons.git
  h.eq("\u{eadc} ", git.added, "git.added")
  h.eq("\u{eade} ", git.modified, "git.modified")
  h.eq("\u{eadf} ", git.removed, "git.removed")
end)

h.test("LazyVim's icon options carry the extra groups", function()
  for _, group in ipairs({ "file_status", "modes", "separators", "ui", "misc" }) do
    for name, glyph in pairs(icons[group]) do
      h.eq(glyph, LazyVim.config.icons[group][name], group .. "." .. name)
    end
  end
  -- LazyVim's own groups the Icon set doesn't define are kept.
  h.eq(true, LazyVim.config.icons.misc.dots ~= nil, "misc.dots kept")
  h.eq(true, LazyVim.config.icons.dap ~= nil, "dap kept")
end)

h.test("file statuses are the glyphs neo-tree shows for git status", function()
  h.eq("\u{f0776}", icons.file_status.modified, "file_status.modified")
  local names = vim.tbl_keys(icons.file_status)
  table.sort(names)
  h.eq(
    { "added", "conflict", "deleted", "ignored", "modified", "renamed", "staged", "unstaged", "untracked" },
    names,
    "file_status names"
  )
end)

h.test("the Explorer's folder and git-status glyphs are the Icon set's", function()
  local components = require("neo-tree").ensure_config().default_component_configs
  h.eq(icons.file_status, components.git_status.symbols, "git status")
  h.eq(icons.ui.FolderAlt, components.icon.folder_closed, "folder_closed")
  h.eq(icons.ui.FolderOpenAlt, components.icon.folder_open, "folder_open")
end)

h.test("the gutter's git signs are the Icon set's git signs", function()
  local opts = LazyVim.opts("gitsigns.nvim")
  for _, signs in ipairs({ opts.signs, opts.signs_staged }) do
    h.eq(icons.git.added, signs.add.text, "add")
    h.eq(icons.git.modified, signs.change.text, "change")
    h.eq(icons.git.removed, signs.delete.text, "delete")
    h.eq(icons.git.removed, signs.topdelete.text, "topdelete")
    h.eq(icons.git.modified, signs.changedelete.text, "changedelete")
  end
  h.eq(icons.git.added, opts.signs.untracked.text, "untracked")
end)

h.test("the module loads on its own, with no globals or other modules", function()
  local chunk = assert(loadfile(root .. "/lua/util/icons.lua"))
  setfenv(chunk, {})
  local ok, set = pcall(chunk)
  h.eq(true, ok, "loads in an empty environment: " .. tostring(set))
  h.eq("table", type(set.kinds), "kinds group")
end)

h.test("padding follows LazyVim's convention: one trailing space at most", function()
  for group, entries in pairs(icons) do
    if group ~= "separators" then
      for name, glyph in pairs(entries) do
        h.eq(false, glyph:find("^%s") ~= nil or glyph:find("%s%s$") ~= nil, group .. "." .. name .. " padding")
      end
    end
  end
  for _, group in ipairs({ "kinds", "diagnostics" }) do
    for name, glyph in pairs(icons[group]) do
      h.eq(true, glyph:find("%S $") ~= nil, group .. "." .. name .. " ends in one space")
    end
  end
end)

-- The default TOML glyph (U+E6B2) is missing from the terminal's symbol font.
h.test("TOML files get the Icon set's TOML glyph", function()
  local toml = icons.misc.toml
  h.eq("\u{e615}", toml, "misc.toml")
  local MiniIcons = require("mini.icons")
  h.eq(toml, (MiniIcons.get("extension", "toml")), "extension toml")
  h.eq(toml, (MiniIcons.get("filetype", "toml")), "filetype toml")
  h.eq("MiniIconsOrange", select(2, MiniIcons.get("filetype", "toml")), "keeps its colour")
  for _, file in ipairs({ "Cargo.toml", "pyproject.toml", "/some/project/config.toml" }) do
    h.eq(toml, (MiniIcons.get("file", file)), file)
    -- bufferline and neo-tree ask through nvim-web-devicons, which mini.icons mocks.
    h.eq(toml, (require("nvim-web-devicons").get_icon(vim.fs.basename(file), "toml")), file .. " (devicons)")
  end
end)
