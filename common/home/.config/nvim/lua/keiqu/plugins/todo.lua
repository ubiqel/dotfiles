return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/trouble.nvim" },
    opts = {
      search = {
        args = {
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--trim",
          "--hidden",
          "-g=!vendor/",
          "-g=!.venv/",
          "-g=!venv/",
          "-g=!.mypy_cache/",
          "-g=!.git/",
        },
      },
    },
    keys = {
      {
        "<leader>xt",
        "<cmd>Trouble todo toggle<cr>",
        desc = "Todo Comments (Trouble)",
      },
    },
    ft = {
      "markdown",
      "go",
      "python",
      "helm",
      "yaml",
      "lua",
      "javascript",
      "typescript",
      "java",
      "bash",
      "fish",
      "html",
      "css",
    },
    config = true,
  },
}
