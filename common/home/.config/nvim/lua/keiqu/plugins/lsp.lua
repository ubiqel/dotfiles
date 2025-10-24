return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    version = "v2.4.0",
    config = function() require("keiqu.lsp") end, -- TODO: move to plugins folder
  },
}
