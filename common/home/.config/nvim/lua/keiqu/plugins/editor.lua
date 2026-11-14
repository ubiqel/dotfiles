return {
  {
    "numToStr/Comment.nvim",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
  "tpope/vim-surround",
  "tpope/vim-repeat",
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>j", "<cmd>TSJToggle<cr>", desc = "Toggle split/join" },
    },
    opts = { use_default_keymaps = false, max_join_length = 140 },
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File explorer" },
      { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file in explorer" },
    },
    opts = { git = { ignore = false } },
  },
  {
    "rmagatti/auto-session",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      suppressed_dirs = { "~/", "~/code", "~/Downloads", "/", "~/work" },
      git_use_branch_name = true,
      session_lens = {
        load_on_setup = true,
      },
    },
  },
  { "mbbill/undotree" },
  { "folke/zen-mode.nvim" },
}
