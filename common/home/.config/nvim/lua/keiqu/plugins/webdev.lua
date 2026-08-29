return {
  {
    "brianhuster/live-preview.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      browser = "firefox",
      dynamic_root = false,
      picker = "telescope",
    },
  },
}
