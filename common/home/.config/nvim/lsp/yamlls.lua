-- Keep the default YAML filetypes, but only activate for GitLab CI files.
return {
  root_dir = function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name:match("%.gitlab%-ci%.ya?ml$") then
      on_dir(vim.fs.root(bufnr, { ".git" }) or vim.fn.getcwd())
    end
  end,
}
