local servers = require("keiqu.lsp.servers")

local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.workspace = vim.tbl_deep_extend("force", capabilities.workspace or {}, {
  fileOperations = {
    didRename = true,
    willRename = true,
  },
})

vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.diagnostic.config({
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    },
  },
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

require("keiqu.lsp.keymaps").setup()

vim.lsp.enable(servers.enabled)
