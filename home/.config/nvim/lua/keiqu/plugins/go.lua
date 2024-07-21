return {
  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = { lsp_codelens = false },
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
  },
}
