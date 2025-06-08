-- TODO: move to separate files
return {
  "tpope/vim-dotenv",
  "tpope/vim-dispatch",
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "J", "<cmd>TSJToggle<cr>" },
    },
    opts = { use_default_keymaps = false, max_join_length = 140 },
  },

  "tpope/vim-commentary",
  "tpope/vim-surround",
  "tpope/vim-repeat",
  "psliwka/vim-smoothie",
  {
    "windwp/nvim-autopairs",
    config = true,
  },
  {
    "rmagatti/auto-session",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      auto_session_suppress_dirs = { "~/", "~/code", "~/Downloads", "/", "~/work" },
      auto_session_use_git_branch = true,

      session_lens = {
        load_on_setup = true,
      },
    },
    init = function()
      vim.keymap.set("n", "<leader>qs", require("auto-session.session-lens").search_session, {
        noremap = true,
      })
    end,
  },
  { "simrat39/symbols-outline.nvim", config = true },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "LspAttach",
    cmd = "Trouble",
    opts = {},
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { git = { ignore = false } },
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  { "mbbill/undotree" },
}
