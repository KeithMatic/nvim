-- Helper booted by toggles_spec.lua to verify restoration in a fresh process.
local h = require("harness")

h.test("restores ordinary toggles and leaves temporary modes off", function()
  local mode = vim.env.TOGGLE_BOOT_MODE
  if mode == "migration" then
    h.eq(false, require("theme").statusline_filename, "legacy statusline filename")
    -- Moved, not copied: a later :ToggleStateReset can't bring the legacy value back.
    vim.cmd.ToggleStateReset()
    local theme = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath("state") .. "/theme.json"), "\n"))
    h.eq(nil, theme.statusline_filename, "legacy value left in theme.json")
    h.eq("tokyonight-moon", theme.theme, "theme kept")
    return
  elseif mode == "override" then
    h.eq(true, require("theme").statusline_filename, "new toggle state overrides legacy theme state")
    return
  end

  h.eq(0, vim.o.showtabline, "tabline")
  h.eq(false, vim.o.wrap, "wrap default")
  h.eq(true, vim.o.spell, "spelling default")
  h.eq(false, vim.diagnostic.is_enabled(), "diagnostics")
  h.eq(false, require("dropbar_config").enabled(), "Dropbar")
  h.eq(false, vim.g.autoformat, "global formatting")
  -- Local choices are defaults for files opened after startup.
  vim.cmd.edit(vim.fn.tempname() .. ".lua")
  vim.wait(200, function()
    return false
  end)
  h.eq(false, vim.b.autoformat, "buffer formatting in a file opened after startup")
  h.eq(false, vim.wo.wrap, "wrap in a file opened after startup")
  h.eq(true, vim.wo.spell, "spelling in a file opened after startup")
  h.eq(true, vim.g.minianimate_disable, "animations")
  h.eq(true, vim.g.minipairs_disable, "Mini Pairs")
  h.eq(false, Snacks.indent.enabled, "indent guides")
  h.eq(false, Snacks.scroll.enabled, "smooth scrolling")
  h.eq(false, Snacks.dim.enabled, "dim starts off")
  h.eq(false, Snacks.profiler.running(), "profiler starts off")
  -- Saved off, but not restored: Snacks' default (on, drawn only while profiling).
  h.eq(true, Snacks.profiler.ui.enabled, "profiler highlights keep their default")
  h.eq(false, Snacks.toggle.zoom():get(), "zoom starts off")
  h.eq(false, Snacks.toggle.zen():get(), "zen starts off")
end)
