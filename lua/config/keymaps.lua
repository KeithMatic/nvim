-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- One table per mode, the design carried over from the AstroNvim mappings.lua.
-- Where a key here would duplicate one LazyVim or this config already has, the
-- existing key won and the duplicate isn't here (docs/keymap-port-design.md).

--- Set every key in `modes`: { [mode] = { [lhs] = { rhs, desc = …, … } } }.
--- The entry's named fields are vim.keymap.set's opts.
---@param modes table<string, table<string, table>>
local function set_keymaps(modes)
  for mode, maps in pairs(modes) do
    for lhs, spec in pairs(maps) do
      local opts = {}
      for k, v in pairs(spec) do
        if type(k) == "string" then
          opts[k] = v
        end
      end
      vim.keymap.set(mode, lhs, spec[1], opts)
    end
  end
end

--- An expr rhs: `keys` in an editable file's buffer, else the key's own
--- meaning, so Enter still jumps in quickfix and runs a q: line.
---@param keys string
---@param own string
local function in_file(keys, own)
  return function()
    if vim.bo.buftype == "" and vim.bo.modifiable then
      return keys
    end
    return own
  end
end

-- The Terminal manager (lua/terminal.lua) takes over LazyVim's Snacks terminal keys.
local terminal = require("terminal")

set_keymaps({
  n = {
    -- AstroNvim's shortcuts use Celeste's gc/gcc; project search remains on <leader>sg.
    ["<leader>/"] = { "gcc", remap = true, desc = "Toggle comment line" },
    -- Re-assert Celeste's insertion helpers after LazyVim's built-in aliases load.
    ["gco"] = { '<Cmd>lua require("celeste_comment").H.insert_comment("below")<CR>', desc = "Add comment below" },
    ["gcO"] = { '<Cmd>lua require("celeste_comment").H.insert_comment("above")<CR>', desc = "Add comment above" },

    -- The code runner (:RunFile, set up in autocmds.lua). <leader>cx is free in LazyVim's "code" group.
    ["<leader>cx"] = { "<Cmd>RunFile<CR>", desc = "Run File" },

    ["<C-/>"] = { terminal.toggle, desc = "Terminal Manager" },
    ["<C-_>"] = { terminal.toggle, desc = "which_key_ignore" },
    ["<leader>ft"] = {
      function()
        terminal.new_at(LazyVim.root())
      end,
      desc = "Terminal (Root Dir)",
    },
    ["<leader>fT"] = {
      function()
        terminal.new_at(vim.fn.expand("%:p:h"))
      end,
      desc = "Terminal (File Dir)",
    },

    -- The cheat sheet: every keymap and feature (the README), from anywhere.
    -- <leader>sK is free beside LazyVim's <leader>sk, which searches the keymaps.
    ["<leader>sK"] = {
      function()
        require("cheat_sheet").open()
      end,
      desc = "Keymaps & Features",
    },

    -- mini.files on the current file, as <leader>fm; the cwd for a buffer with no file.
    ["-"] = {
      function()
        local file = vim.api.nvim_buf_get_name(0)
        require("mini.files").open(vim.uv.fs_stat(file) and file or nil, true)
      end,
      desc = "Open mini.files (File's Folder)",
    },

    -- Shadows increment; visual g<C-a> still increments, and vag also selects all.
    ["<C-a>"] = { "ggVG", desc = "Select All" },
    ["<C-c>"] = { "<Cmd>%y+<CR>", desc = "Copy File to Clipboard" },
    -- The enclosing { } block, linewise. Bare Y now waits timeoutlen.
    ["YY"] = { "va{Vy", desc = "Yank Brace Block" },
    ["U"] = { "<Cmd>redo<CR>", desc = "Redo" },
    -- Shrinks a run of spaces under the cursor to one.
    ["d."] = { "viwhd", desc = "Delete Extra Space" },

    ["<CR>"] = { in_file("ciw", "<CR>"), expr = true, desc = "Change Word" },
    ["<BS>"] = { in_file("ci", "<BS>"), expr = true, desc = "Change Inside" },

    -- LazyVim's n/N (always down / always up, folds opened), centred too.
    ["n"] = { "'Nn'[v:searchforward].'zzzv'", expr = true, desc = "Go to Next Match" },
    ["N"] = { "'nN'[v:searchforward].'zzzv'", expr = true, desc = "Go to Prev Match" },
    ["*"] = { "*zzzv", desc = "Search Word Forward" },
    ["#"] = { "#zzzv", desc = "Search Word Backward" },
    ["g*"] = { "g*zz", desc = "Search Partial Word Forward" },
    ["g#"] = { "g#zz", desc = "Search Partial Word Backward" },

    -- Yank a motion, then open :s on the line, prefilled with it
    -- (\C case-sensitive, \< \> whole word); type the replacement and Enter.
    ["yrw"] = { "yiw:s/\\C\\<<C-R>0\\>/", desc = "Replace Inner Word" },
    ["yrW"] = { "yiW:s/\\C\\<<C-R>0\\>/", desc = "Replace Inner WORD" },
    ["yre"] = { "ye:s/\\C\\<<C-R>0\\>/", desc = "Replace to End of Word" },
    ["yrE"] = { "yE:s/\\C\\<<C-R>0\\>/", desc = "Replace to End of WORD" },
  },

  t = {
    ["<C-/>"] = { terminal.toggle, desc = "Terminal Manager" },
    ["<C-_>"] = { terminal.toggle, desc = "which_key_ignore" },
  },

  i = {
    ["<M-o>"] = { "<C-o>o", desc = "Open Line Below" },
    ["<M-O>"] = { "<C-o>O", desc = "Open Line Above" },
    -- <M-j>/<M-k> stay LazyVim's move-line. <C-d>/<C-t> keep the cursor on its character.
    ["<M-h>"] = { "<C-d>", desc = "Outdent Line" },
    ["<M-l>"] = { "<C-t>", desc = "Indent Line" },
    -- blink.cmp's <C-e> hides an open menu first and falls back to this.
    ["<C-a>"] = { "<Esc>^i", desc = "Go to Line Start" },
    ["<C-e>"] = { "<End>", desc = "Go to Line End" },
  },

  -- Visual only, not Select: r typed over a snippet placeholder stays r.
  x = {
    ["<leader>/"] = { "gc", remap = true, desc = "Toggle comment" },
    -- :%s/…//g prefilled with the selection, matched literally (\V); the cursor
    -- waits in the replacement.
    ["r"] = {
      [[y:%s/\V\C<C-R>=escape(@0, '/\')->substitute("\n", '\\n', 'g')<CR>//g<Left><Left>]],
      desc = "Replace Selection in File",
    },
  },
})

-- Show or hide the statusline's filename (lua/statusline.lua). <leader>uN is free in LazyVim's "ui" group.
require("statusline").filename_toggle():map("<leader>uN")

-- Every current toggle has an explicit persistence policy. Local choices
-- become future buffer defaults; temporary modes always start off.
require("persistent_toggles").setup()
