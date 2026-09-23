-- UI: the themes and their transparency, the statusline (lua/statusline.lua),
-- mode colours, float borders the 'winborder' option doesn't reach, the curated
-- theme picker, the cursor trail, the motion hints, lspsaga's Breadcrumbs, rename
-- and outline, and noice's cmdline popup (centred, with the Icon set's glyphs)
-- and its menu, and the Dashboard's header and sections (lua/dashboard.lua).
-- Transparency the themes' own options leave out, and the tint, are done in
-- lua/theme.lua.

return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Restores the last theme applied (see lua/theme.lua).
      colorscheme = function()
        require("theme").load()
      end,
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = { sidebars = "transparent", floats = "transparent" },
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      transparent_background = true,
      float = { transparent = true },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "meuter/lualine-so-fancy.nvim" }, -- its diff (lua/statusline.lua)
    opts = function(_, opts)
      opts.options.theme = require("theme").lualine
      -- No powerline arrows: they'd be drawn in the (now cleared) section colours.
      opts.options.section_separators = { left = "", right = "" }
      require("statusline").extend(opts)
    end,
  },
  {
    -- Tints the cursor line and selection by mode. Its colours come from the
    -- theme's palette: lua/theme.lua sets them on every theme change.
    "mvllow/modes.nvim",
    event = "VeryLazy",
    opts = {
      line_opacity = 0.2,
      set_cursorline = false, -- leave 'cursorline' on everywhere, as LazyVim sets it
    },
    config = function(_, opts)
      -- It fades its colours over Normal's background, which transparency clears.
      require("theme").with_background(function()
        require("modes").setup(opts)
      end)
    end,
  },
  {
    -- An animated cursor trail. Neovide animates its own cursor.
    "gen740/smoothcursor.nvim",
    cond = vim.g.neovide == nil,
    lazy = false,
    opts = {
      autostart = true,
      fancy = { enable = true },
    },
  },
  {
    -- Motion hints (w, b, e, ^, $, ...) under the cursor line: hidden until
    -- toggled with <leader>uP, for practising motions.
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = { startVisible = false },
    config = function(_, opts)
      local precognition = require("precognition")
      precognition.setup(opts)
      Snacks.toggle({
        name = "Precognition",
        get = precognition.is_visible,
        set = function(state)
          if state then
            precognition.show()
          else
            -- hide() also deletes the autocmd that restores the hints' highlight
            -- on theme change; setup() hides (startVisible = false) and re-adds it.
            precognition.setup(opts)
          end
        end,
      }):map("<leader>uP")
    end,
  },
  {
    -- Breadcrumbs, rename and outline only, under <leader>k: LazyVim already
    -- gives the rest (code actions, hover, diagnostics, references).
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    keys = {
      { "<leader>kr", "<cmd>Lspsaga rename<cr>", desc = "Rename" },
      { "<leader>ko", "<cmd>Lspsaga outline<cr>", desc = "Outline" },
    },
    opts = {
      symbol_in_winbar = { enable = true },
      lightbulb = { enable = false },
      beacon = { enable = false },
    },
    config = function(_, opts)
      require("lspsaga").setup(opts)
      local winbar = require("lspsaga.symbol.winbar")
      -- lspsaga checks this flag on every redraw (its own winbar_toggle leaves
      -- a redraw hook behind, so the Breadcrumbs come back on their own).
      local breadcrumbs = require("lspsaga").config.symbol_in_winbar

      -- Buffers that attached while the Breadcrumbs were off never got
      -- lspsaga's redraw hook: add it when they're shown.
      local function show(buf)
        local hooked = pcall(vim.api.nvim_get_autocmds, { group = "SagaWinbar" .. buf })
        if not hooked and #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/documentSymbol" }) > 0 then
          winbar.init_winbar(buf)
        end
        winbar.get_bar()
      end
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("breadcrumbs", { clear = true }),
        callback = function(args)
          if breadcrumbs.enable then
            show(args.buf)
          end
        end,
      })

      Snacks.toggle({
        name = "Breadcrumbs",
        get = function()
          return breadcrumbs.enable
        end,
        set = function(state)
          breadcrumbs.enable = state
          if state then
            return show(vim.api.nvim_get_current_buf())
          end
          -- Only lspsaga's winbars: others (nvim-dap-ui's) stay.
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.startswith(vim.wo[win].winbar, "%#Saga") then
              vim.wo[win].winbar = ""
            end
          end
        end,
      }):map("<leader>kb")
    end,
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      -- Appended: a list in opts would replace LazyVim's groups, not add to them.
      table.insert(opts.spec, { "<leader>k", group = "lspsaga" })
    end,
  },
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      local icons = require("util.icons")
      -- A cmdline format showing `glyph`: noice puts its own space after it.
      local function format_with(glyph)
        return { icon = vim.trim(glyph) }
      end
      local search = vim.trim(icons.ui.Search) .. " "

      opts.presets = vim.tbl_extend("force", opts.presets or {}, {
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true, -- LSP hover and signature help
      })
      -- Top-level views are merged after the presets, so these win over
      -- LazyVim's command_palette preset (which puts the popup near the top).
      opts.views = vim.tbl_deep_extend("force", opts.views or {}, {
        cmdline_popup = {
          position = { row = "50%", col = "50%" }, -- the exact centre of the screen
          size = { width = "20%", max_width = 50 },
        },
      })
      opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
        format = {
          cmdline = format_with(icons.misc.Vim),
          search_down = format_with(search .. icons.ui.ChevronShortDown),
          search_up = format_with(search .. icons.ui.ChevronShortUp),
          filter = format_with(icons.ui.Terminal), -- :!, run in the shell
          lua = format_with(icons.misc.lua),
          help = format_with(icons.diagnostics.Question),
        },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          -- blink opens the cmdline's menu on the row after the one given here.
          -- By default that's the row below the cmdline's text: in noice's popup
          -- that's the bottom border, so give the frame's last row instead.
          cmdline_position = function()
            local cmdline = package.loaded.noice and require("noice").api.get_cmdline_position()
            if cmdline and vim.api.nvim_win_is_valid(cmdline.win) then
              -- noice draws the frame (border and padding) as a window of its
              -- own, which the text's window sits in.
              local config = vim.api.nvim_win_get_config(cmdline.win)
              local frame = config.relative == "win" and config.win or cmdline.win
              local last_row = vim.api.nvim_win_get_position(frame)[1] + vim.api.nvim_win_get_height(frame) - 1
              return { last_row, cmdline.screenpos.col - 1 }
            end
            -- No noice cmdline: blink's own default.
            local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed, from any UI plugin
            if pos then
              return { pos[1] - 1, pos[2] }
            end
            return { vim.o.lines - math.max(vim.o.cmdheight, 1), 0 }
          end,
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    init = function()
      -- Now, not on VeryLazy: the Dashboard opens before then.
      require("dashboard").setup()
    end,
    opts = {
      -- Only the header and sections: LazyVim's keys and pick stay.
      dashboard = {
        preset = { header = require("dashboard").header },
        sections = require("dashboard").sections,
      },
    },
    keys = {
      -- The only change to an existing LazyVim key: same picker, curated themes.
      {
        "<leader>uC",
        function()
          require("theme").pick()
        end,
        desc = "Colorschemes",
      },
    },
  },
}
