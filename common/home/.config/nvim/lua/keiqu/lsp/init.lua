local defaults = require("keiqu.lsp.defaults")
defaults.setup()

local servers = {
  "gopls",
  "basedpyright",
  "lua_ls",
  "bashls",
  "vtsls",
  "helm_ls",
  "jdtls",
  "templ",
  "html",
  "htmx",
  "yamlls",
  "clangd",
  "plantuml_lsp",
  "gradle_ls",
  "lemminx",
  "omnisharp",
  "gdscript",
  "rust_analyzer",
}

local handlers = require("keiqu.lsp.handlers")
handlers.setup()

for _, server in pairs(servers) do
  local opts = {
    on_attach = handlers.on_attach,
    capabilities = handlers.capabilities,
  }

  local has_custom_opts, custom_opts = pcall(require, "keiqu.lsp.settings." .. server)
  if has_custom_opts then
    opts = vim.tbl_deep_extend("force", opts, custom_opts)
  end

  vim.lsp.config(server, opts)
  vim.lsp.enable(server)
end
