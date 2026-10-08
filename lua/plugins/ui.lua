-- UI: the themes and their transparency, the statusline (lua/statusline.lua),
-- mode colours, float borders the 'winborder' option doesn't reach, the curated
-- theme picker, the Buffer sticks, the motion hints, the Habit tips, the Rainbow brackets and
-- the Block guide, Dropbar's Breadcrumbs,
-- lspsaga's rename and outline, and noice's cmdline popup (centred, with the Icon set's glyphs)
-- and its menu, the Dashboard's header and sections (lua/dashboard.lua), and
-- the picker's prompt and pointer (lua/picker.lua).
-- Transparency the themes' own options leave out, and the tint, are done in
-- lua/theme.lua.

-- Where the Block guide never shows: prose, whose indents are lists and quotes,
-- and tool panels.
local prose_and_panels = {
  "markdown",
  "text",
  "rst",
  "org",
  "norg",
  "gitcommit",
  "snacks_dashboard",
  "sqmeow-drawer",
  "sqmeow-result",
}

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
    opts = function(_, opts)
      opts.transparent = true
      opts.styles = vim.tbl_extend(
        "force",
        opts.styles or {},
        { sidebars = "transparent", floats = "transparent" },
        require("theme_italics").styles("tokyonight") -- lua/theme_italics.lua
      )
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = function(_, opts)
      opts.transparent_background = true
      opts.float = vim.tbl_extend("force", opts.float or {}, { transparent = true })
      opts.styles = vim.tbl_extend("force", opts.styles or {}, require("theme_italics").styles("catppuccin"))
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "meuter/lualine-so-fancy.nvim" }, -- its diff (lua/statusline.lua)
    opts = function(_, opts)
      opts.options.theme = require("theme").lualine
      -- No powerline arrows: they'd be drawn in the (now cleared) section colours.
      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "", right = "" } -- no chevrons
      require("statusline").extend(opts)
    end,
    config = function(_, opts)
      require("lualine").setup(opts)
      require("statusline").centre_lualine()
    end,
  },
  -- The Buffer sticks replace bufferline's tabs. They're drawn, and stepped
  -- through, in the Column order (lua/column_order.lua).
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "ahkohd/buffer-sticks.nvim",
    lazy = false, -- the sticks first draw on entering a buffer, so be ready for the first one
    keys = function()
      local order = require("column_order")
      return {
        {
          "<leader>bj",
          function()
            BufferSticks.jump()
          end,
          desc = "Jump to File",
        },
        {
          "<leader>bx",
          function()
            order.pick("close")
          end,
          desc = "Close a File",
        },
        {
          "<leader>bv",
          function()
            order.pick("vsplit")
          end,
          desc = "Open a File in a Vertical Split",
        },
        {
          "<leader>bs",
          function()
            order.pick("split")
          end,
          desc = "Open a File in a Split",
        },
        { "<leader>bp", order.toggle_pin, desc = "Toggle Pin" },
        {
          "<leader>bP",
          function()
            order.close("unpinned")
          end,
          desc = "Close Unpinned Files",
        },
        {
          "<leader>bo",
          function()
            order.close("others")
          end,
          desc = "Close Other Files",
        },
        {
          "<leader>bl",
          function()
            order.close("left")
          end,
          desc = "Close Files Above",
        },
        {
          "<leader>br",
          function()
            order.close("right")
          end,
          desc = "Close Files Below",
        },
        {
          "[B",
          function()
            order.move(-1)
          end,
          desc = "Move File Up",
        },
        {
          "]B",
          function()
            order.move(1)
          end,
          desc = "Move File Down",
        },
        {
          "<S-h>",
          function()
            order.cycle(-1)
          end,
          desc = "Prev File",
        },
        {
          "<S-l>",
          function()
            order.cycle(1)
          end,
          desc = "Next File",
        },
        {
          "[b",
          function()
            order.cycle(-1)
          end,
          desc = "Prev File",
        },
        {
          "]b",
          function()
            order.cycle(1)
          end,
          desc = "Next File",
        },
      }
    end,
    opts = {
      filter = { buftypes = { "terminal", "help", "quickfix", "nofile", "prompt" } },
      preview = { mode = "current" },
      -- Links, so they follow every theme. A link can't add italics, so the
      -- labels are italic only where the theme's comments are.
      highlights = {
        active = { link = "Statement" },
        alternate = { link = "Function" },
        inactive = { link = "Comment" },
        active_modified = { link = "DiagnosticWarn" },
        alternate_modified = { link = "DiagnosticWarn" },
        inactive_modified = { link = "DiagnosticWarn" },
        label = { link = "Comment" },
        filter_title = { link = "Comment" },
        filter_selected = { link = "Statement" },
        list_selected = { link = "Statement" },
      },
    },
    config = function(_, opts)
      require("buffer-sticks").setup(opts)
      require("column_order").setup()
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
      require("line_number").setup()
    end,
  },
  {
    -- Rainbow brackets: pairs found from the syntax tree, so `<<` and
    -- comparisons are never coloured. Its colours come from the theme
    -- (lua/theme.lua). Not lazy: it attaches when a buffer's filetype is set,
    -- including the file Neovim opens with.
    "HiPhish/rainbow-delimiters.nvim",
    lazy = false,
    init = function()
      vim.g.rainbow_delimiters = { highlight = require("theme").rainbow }
    end,
  },
  {
    -- Motion hints (w, b, e, ^, $, ...) under the cursor line: hidden until
    -- toggled with <leader>uP, for practising motions. No debounce: their
    -- virtual line follows the cursor a row at a time, whereas a debounce
    -- removes it on every line change and the text below jumps up and back.
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = function()
      return { startVisible = require("toggle_state").get("ui.precognition", false) }
    end,
    config = function(_, opts)
      local precognition = require("precognition")
      precognition.setup(opts)
      require("toggle_state")
        .persist(
          "ui.precognition",
          Snacks.toggle({
            name = "Motion hints",
            get = precognition.is_visible,
            set = function(state)
              if state then
                precognition.show()
              else
                -- hide() also deletes the autocmd that restores the hints'
                -- highlight on theme change; setup() re-adds it.
                precognition.setup(vim.tbl_extend("force", opts, { startVisible = false }))
              end
            end,
          }),
          { default = false, restore = false }
        )
        :map("<leader>uP")
    end,
  },
  {
    -- Habit tips: the better command for something just done the long way,
    -- quietened with <leader>ut and never shown in a Layer (lua/habit_tips.lua).
    "kamegoro/tobira.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>mm", "<cmd>Tobira<cr>", desc = "Next Tip" },
      { "<leader>mg", "<cmd>TobiraGuide<cr>", desc = "Tip Guide" },
      { "<leader>mp", "<cmd>TobiraProgress<cr>", desc = "Progress" },
      { "<leader>ms", "<cmd>TobiraStats<cr>", desc = "Stats" },
      -- No key for :TobiraReset: it wipes every count without asking.
    },
    opts = {},
    config = function(_, opts)
      require("habit_tips").setup(opts)
    end,
  },
  {
    -- Rename and outline only: LazyVim already gives the rest (code actions,
    -- hover, diagnostics, references), and Dropbar owns the Breadcrumbs.
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    keys = {
      { "<leader>kr", "<cmd>Lspsaga rename<cr>", desc = "Rename" },
      { "<leader>ko", "<cmd>Lspsaga outline<cr>", desc = "Outline" },
    },
    opts = {
      symbol_in_winbar = { enable = false },
      lightbulb = { enable = false },
      beacon = { enable = false },
    },
  },
  {
    -- No diagnostic icons in the gutter: the message at the end of the line
    -- and the statusline's count already show them.
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.diagnostics.signs = false
    end,
  },
  -- No git icons in the gutter either, until <leader>uG shows them
  -- (lua/persistent_toggles.lua); hunks and blame work without them.
  { "lewis6991/gitsigns.nvim", opts = { signcolumn = false } },
  {
    "Bekaboo/dropbar.nvim",
    lazy = false,
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    keys = {
      {
        "<leader>;",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Pick Breadcrumbs",
      },
      {
        "[;",
        function()
          require("dropbar.api").goto_context_start()
        end,
        desc = "Breadcrumbs Context Start",
      },
      {
        "];",
        function()
          require("dropbar.api").select_next_context()
        end,
        desc = "Breadcrumbs Next Context",
      },
      {
        "<leader>kb",
        function()
          require("dropbar_config").toggle():toggle()
        end,
        desc = "Toggle Breadcrumbs",
      },
    },
    opts = function()
      local api = require("dropbar.api")
      local configs = require("dropbar.configs")
      local menu = require("dropbar.utils.menu")

      local function click()
        local current = menu.get_current()
        if not current then
          return
        end
        local cursor = vim.api.nvim_win_get_cursor(current.win)
        local component = current.entries[cursor[1]]:first_clickable(cursor[2])
        if component then
          current:click_on(component, nil, 1, "l")
        end
      end

      return {
        bar = {
          enable = require("dropbar_config").enable(configs.opts.bar.enable),
          -- SQL buffers lead with the database their queries run on (lua/database.lua).
          sources = require("database").sources(configs.opts.bar.sources),
        },
        menu = {
          keymaps = {
            ["<C-h>"] = "<C-w>q",
            ["<C-j>"] = "j",
            ["<C-k>"] = "k",
            ["<C-l>"] = click,
          },
        },
        fzf = {
          keymaps = {
            ["<C-h>"] = function()
              local current = menu.get_current()
              if current then
                current:fuzzy_find_close()
              end
            end,
            ["<C-l>"] = api.fuzzy_find_click,
          },
        },
      }
    end,
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      -- Appended: a list in opts would replace LazyVim's groups, not add to them.
      table.insert(opts.spec, { "<leader>k", group = "navigation" })
      table.insert(opts.spec, {
        "<leader>m",
        group = "habit tips",
        icon = { icon = vim.trim(require("util.icons").misc.lightbulb), color = "yellow" },
      })
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
      -- The Block guide jumps into place while typing, rather than animating in
      -- on every new line.
      local group = vim.api.nvim_create_augroup("block_guide", { clear = true })
      vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
        group = group,
        callback = function(ev)
          -- Cleared on leaving, so the global setting applies again.
          if ev.event == "InsertEnter" then
            vim.b[ev.buf].snacks_animate_indent = false
          else
            vim.b[ev.buf].snacks_animate_indent = nil
          end
        end,
      })
    end,
    opts = {
      -- The Block guide: only the block the cursor is in (its bracket lines
      -- too), no guides for the others. Snacks colours it by indent level, which
      -- matches the Rainbow brackets in formatted code, faded (lua/theme.lua).
      indent = {
        indent = { enabled = false },
        scope = { char = require("util.icons").ui.LineDashedMiddle, hl = require("theme").guide },
        animate = { style = "out", duration = { step = 10, total = 150 } },
        filter = function(buf)
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and vim.bo[buf].buftype == ""
            and not vim.list_contains(prose_and_panels, vim.bo[buf].filetype)
        end,
      },
      -- The header and sections; LazyVim's keys and pick stay, plus the
      -- cheat sheet's key (below).
      dashboard = {
        preset = { header = require("dashboard").header },
        sections = require("dashboard").sections,
      },
      -- The Icon set's prompt and pointer (lua/picker.lua).
      picker = {
        prompt = require("picker").prompt,
        win = { list = { wo = { statuscolumn = "%!v:lua.require'picker'.statuscolumn()" } } },
      },
      -- Habit tips' notice for each key they leave out stays in the history
      -- only (lua/habit_tips.lua). Loaded on the first notification, not here.
      notifier = {
        filter = function(notif)
          return require("habit_tips").show_notice(notif)
        end,
      },
    },
    keys = {
      -- The only change to an existing LazyVim key: same picker, curated themes.
      {
        "<leader>uC",
        function()
          require("theme").pick()
        end,
        desc = "Curated themes",
      },
      {
        "<leader>uy",
        function()
          require("theme_italics").pick()
        end,
        desc = "Theme Italics",
      },
    },
  },
  {
    -- The cheat sheet's key on the Dashboard, before Quit (lua/dashboard.lua). A
    -- function, so it adds to LazyVim's list: a list in opts would be merged
    -- into it item by item, replacing Find File.
    "folke/snacks.nvim",
    opts = function(_, opts)
      require("dashboard").add_keys(opts.dashboard.preset.keys)
    end,
  },
}
