local M = {}

M.setup = function()
  -- dirty hack to add plantuml_lsp
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then
    vim.notify("Plugin 'lspconfig' not found!", vim.log.levels.ERROR)
    return
  end

  local configs_ok, configs = pcall(require, "lspconfig.configs")
  if not configs_ok then
    vim.notify("Plugin 'lspconfig.configs' not found!", vim.log.levels.ERROR)
    return
  end

  -- define your custom LSP server only if not defined yet
  if not configs.plantuml_lsp then
    configs.plantuml_lsp = {
      default_config = {
        cmd = {
          "plantuml-lsp",
          -- "--stdlib-path=/path/to/plantuml-stdlib",
          "--exec-path=plantuml",
        },
        filetypes = { "plantuml" },
        root_dir = function(fname) return lspconfig.util.find_git_ancestor(fname) or vim.fn.getcwd() end,
        settings = {},
      },
    }
  end
end

return M
