local group = vim.api.nvim_create_augroup("keiqu_filetype", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    local bufnr = args.buf
    if not pcall(vim.treesitter.start, bufnr) then
      return
    end

    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and vim.treesitter.query.get(lang, "indents") then
      vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
