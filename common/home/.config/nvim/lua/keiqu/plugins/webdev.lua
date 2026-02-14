return {
  {
    "brianhuster/live-preview.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = {
      browswer = "firefox",
      dynamic_root = false,
      picker = "telescope",
    },
  },
}
