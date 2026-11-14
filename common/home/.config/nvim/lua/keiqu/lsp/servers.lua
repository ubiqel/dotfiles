-- Servers enabled by vim.lsp.enable().
local enabled = {
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
  "rust_analyzer",
  "ols",
}

-- These are not Mason packages and must be installed separately.
local not_in_mason = {
  plantuml_lsp = true,
}

local mason = vim.tbl_filter(function(server) return not not_in_mason[server] end, enabled)

return {
  enabled = enabled,
  mason = mason,
}
