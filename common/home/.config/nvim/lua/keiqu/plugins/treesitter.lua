return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = { ":TSInstall all", ":TSUpdate all" },
    branch = "main",
    dependencies = {
      -- "nvim-treesitter/playground",
      -- "nvim-treesitter/nvim-treesitter-textobjects",
    },
    -- main = "nvim-treesitter.configs",
    lazy = false,
    opts = {
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      playground = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "g[",
          scope_incremental = "gs[",
          node_decremental = "g]",
        },
      },
    },
  },
}
