return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "storm",
      sidebars = { "NvimTree" },
      lualine_bold = true,
    },
  },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  { "ellisonleao/gruvbox.nvim", priority = 1000 },
  { "rebelot/kanagawa.nvim", priority = 1000 },
}
