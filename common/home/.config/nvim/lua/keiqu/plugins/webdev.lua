return {
  {
    "brianhuster/live-preview.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = {
      -- browser = "firefox",
      dynamic_root = false,
      picker = "telescope",
    },
  },
}
