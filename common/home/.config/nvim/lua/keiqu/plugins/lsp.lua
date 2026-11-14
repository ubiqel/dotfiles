return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  version = "v2.12.0",
  dependencies = {
    {
      "mason-org/mason-lspconfig.nvim",
      dependencies = { "mason.nvim" },
      opts = {
        ensure_installed = require("keiqu.lsp.servers").mason,
        automatic_enable = false,
      },
    },
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function() require("keiqu.lsp") end,
}
