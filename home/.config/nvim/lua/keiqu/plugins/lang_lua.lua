return {
  "milisims/nvim-luaref",
  {
    "folke/neodev.nvim",
    dependencies = { "neovim/nvim-lspconfig", "nvim-neotest/nvim-nio" },
    opts = {
      library = { plugins = { "nvim-dap-ui" }, types = true },
    },
    priority = 100, -- make sure to load this before lspconfig
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = { ensure_installed = { "stylua" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
}
