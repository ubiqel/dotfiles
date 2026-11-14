return {
  cmd = { "plantuml-lsp", "--exec-path=plantuml" },
  filetypes = { "plantuml" },
  root_dir = function(bufnr, on_dir) on_dir(vim.fs.root(bufnr, { ".git" }) or vim.fn.getcwd()) end,
}
