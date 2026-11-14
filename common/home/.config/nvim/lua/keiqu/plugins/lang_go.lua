return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },
  {
    "leoluz/nvim-dap-go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
    keys = {
      { "<leader>dt", function() require("dap-go").debug_test() end, desc = "Debug test" },
    },
  },
}
