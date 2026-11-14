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
        ["*"] = { "trim_whitespace", "trim_newlines" },
        go = { "goimports", "gofumpt" },
        lua = { "stylua" },
        python = { "isort" },
        rust = { "rustfmt" },
        odin = { "odinfmt" },
        fish = { "fish_indent" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },
}
