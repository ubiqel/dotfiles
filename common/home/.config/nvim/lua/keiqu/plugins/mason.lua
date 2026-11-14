local tools = {
  "stylua",
  "gofumpt",
  "goimports",
  "gomodifytags",
  "impl",
  "delve",
  "gotestsum",
  "isort",
  "mypy",
  "gitlint",
  "hadolint",
  "tree-sitter-cli",
}

return {
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    keys = {
      { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" },
    },
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = tools,
      run_on_start = true,
    },
  },
}
