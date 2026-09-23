-- Editing behaviour: the completion Tab chain, the Menu keys, better escape and
-- smart strings.

--- A Menu key's insert-mode fallback: returns `keys` for blink.cmp to type.
--- Anything else (blink also runs it in select mode, where returned keys are
--- dropped) falls through to the key itself, as Tabout does.
---@param keys string
local function insert_move(keys)
  keys = vim.keycode(keys)
  return function()
    if vim.fn.mode() == "i" then
      return keys
    end
  end
end

--- A Menu key's cmdline fallback: blink.cmp ignores keys returned in the
--- cmdline, so type them, ahead of any keys already queued (a macro, a paste).
---@param keys string
local function cmdline_move(keys)
  keys = vim.keycode(keys)
  return function()
    vim.api.nvim_feedkeys(keys, "ni", false)
    return true
  end
end

return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        -- "default" rather than LazyVim's "enter": <CR> never accepts a completion.
        -- It keeps <C-n>/<C-p>, the arrow keys and <C-y> for the menu.
        preset = "default",
        -- The Menu keys: drive the menu, else move the cursor. <C-g>U keeps a
        -- left/right move in the current undo step and dot-repeat; nothing
        -- can for up/down, so those are the arrow keys. <C-k> replaces the
        -- preset's signature toggle (noice opens signature help by itself).
        ["<C-h>"] = { "hide", insert_move("<C-g>U<Left>"), "fallback" },
        ["<C-j>"] = { "select_next", insert_move("<Down>"), "fallback" },
        ["<C-k>"] = { "select_prev", insert_move("<Up>"), "fallback" },
        ["<C-l>"] = { "select_and_accept", insert_move("<C-g>U<Right>"), "fallback" },
        -- The only insert-mode <Tab>: accept → snippet forward → tabout → indent.
        -- Setting it here also stops LazyVim adding its own <Tab> chain, which
        -- would accept AI suggestions (no AI extras are enabled).
        ["<Tab>"] = {
          "select_and_accept",
          "snippet_forward",
          function()
            return require("tabout").tabout()
          end,
          "fallback",
        },
      },
      -- The Menu keys in the cmdline: with no menu, <C-j>/<C-k> recall
      -- history as the arrow keys do, and <C-h>/<C-l> move the cursor.
      cmdline = {
        keymap = {
          ["<C-h>"] = { "hide", cmdline_move("<Left>") },
          ["<C-j>"] = { "select_next", cmdline_move("<Down>") },
          ["<C-k>"] = { "select_prev", cmdline_move("<Up>") },
          ["<C-l>"] = { "select_and_accept", cmdline_move("<Right>") },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    -- A function, since a `keys` list in opts would replace LazyVim's.
    opts = function(_, opts)
      -- LazyVim's insert-mode signature help would shadow the <C-k> Menu key
      -- in buffers whose server attaches after blink.cmp maps it. Spelled as
      -- LazyVim spells it, so the two entries match.
      table.insert(opts.servers["*"].keys, { "<c-k>", false, mode = "i" })
    end,
  },
  -- Better escape: jj and jk leave insert mode and the cmdline (searches too,
  -- abandoning them). The j is typed at once and removed if the second key
  -- follows within 200 ms, so typing never pauses; j and k are both mapped in
  -- those modes. Visual, select and terminal modes keep j (lazygit gets jj).
  {
    "max397574/better-escape.nvim",
    event = "VeryLazy",
    opts = {
      timeout = 200,
      default_mappings = false,
      mappings = {
        i = { j = { j = "<Esc>", k = "<Esc>" } },
        c = { j = { j = "<C-c>", k = "<C-c>" } },
      },
    },
  },
  -- Smart strings: typing a `{…}` placeholder turns a Python string into an
  -- f-string, and typing `${` turns a JS/TS quoted string into a template literal.
  -- It loads per filetype on its own, so it must not be lazy-loaded.
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
    init = function()
      -- Lua conversion (to `("…"):format()`) is on by default despite the README;
      -- the variable is spelled "disabled" in the code, "disable" in the README.
      vim.g.puppeteer_disabled_filetypes = { "lua" }
    end,
  },
}
