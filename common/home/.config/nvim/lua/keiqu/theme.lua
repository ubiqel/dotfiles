local function set_theme()
  if vim.o.background == "dark" then
    vim.cmd.colorscheme("catppuccin-mocha")
  else
    vim.cmd.colorscheme("onedark")
  end
end

local group = vim.api.nvim_create_augroup("keiqu_theme", { clear = true })

vim.api.nvim_create_autocmd("OptionSet", {
  group = group,
  pattern = "background",
  callback = set_theme,
})

-- Wait for startup so lualine can pick up the colorscheme change.
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  nested = true,
  callback = set_theme,
})
