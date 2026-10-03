return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        odinfmt = {
          command = "odinfmt",
          args = { "-stdin" },
          stdin = true,
        },
      },
      formatters_by_ft = {
        odin = { "odinfmt" },
      },
    },
  },
}
