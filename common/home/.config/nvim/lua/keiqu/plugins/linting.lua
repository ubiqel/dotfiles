return {
  {
    "nvimtools/none-ls.nvim",
    main = "null-ls",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.code_actions.gomodifytags,
        nls.builtins.code_actions.impl,
        nls.builtins.code_actions.refactoring,
        nls.builtins.diagnostics.fish,
        nls.builtins.diagnostics.gitlint,
        nls.builtins.diagnostics.hadolint,
        nls.builtins.diagnostics.mypy,
      })
      return opts
    end,
  },
}
