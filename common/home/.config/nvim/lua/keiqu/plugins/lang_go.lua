return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "go", "gomod", "gowork", "gosum" } },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = { ensure_installed = { "goimports", "gofumpt" } },
  },
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = { ensure_installed = { "gomodifytags", "impl" } },
      },
    },
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        -- golang
        nls.builtins.code_actions.gomodifytags,
        nls.builtins.code_actions.impl,

        nls.builtins.code_actions.refactoring,

        -- TODO: move to sep file
        -- nls.builtins.diagnostics.dotenv_linter.with({ // --TODO: creates temp files (why?)
        --   extra_args = { "-s", "UnorderedKey" },
        -- }),
        nls.builtins.diagnostics.fish,
        nls.builtins.diagnostics.gitlint,
        nls.builtins.diagnostics.hadolint,
        nls.builtins.diagnostics.mypy,
        nls.builtins.formatting.fish_indent,
      })

      nls.setup(opts)

      -- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      -- opts.on_attach = function(client, bufnr)
      --   if client.supports_method("textDocument/formatting") then
      --     vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      --     vim.api.nvim_create_autocmd("BufWritePre", {
      --       group = augroup,
      --       buffer = bufnr,
      --       callback = function() vim.lsp.buf.format({ async = false }) end,
      --     })
      --   end
      -- end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        opts = { ensure_installed = { "delve" } },
      },
      {
        "leoluz/nvim-dap-go",
        opts = {},
      },
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "fredrikaverpil/neotest-golang",
    },
    opts = {
      adapters = {
        ["neotest-golang"] = {
          -- Here we can set options for neotest-golang, e.g.
          -- go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
          dap_go_enabled = true, -- requires leoluz/nvim-dap-go
        },
      },
    },
  },
}
