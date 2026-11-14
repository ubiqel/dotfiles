return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["*"] = { "trim_whitespace", "trim_newlines" },
        fish = { "fish_indent" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },
}
