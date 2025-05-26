return {
  {
    "RRethy/vim-illuminate",
    config = function()
      vim.cmd([[
        hi IlluminatedWordText guibg=#3b4261
        hi IlluminatedWordRead guibg=#3b4261
        hi IlluminatedWordWrite guibg=#3b4261
      ]])

      require("illuminate").configure({
        providers = { "lsp", "treesitter" },
        filetypes_denylist = { "netrw", "fugitiveblame" },
      })
    end,
  },
}
