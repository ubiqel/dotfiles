return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    config = function() require("keiqu.lsp") end, -- TODO: move to plugins folder
  },
}
