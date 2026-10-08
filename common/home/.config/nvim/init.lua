require("keiqu.general")
require("keiqu.globals")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("keiqu.plugins")

-- Configure colorscheme
local function set_theme()
  if vim.o.background == "dark" then
    vim.cmd("colorscheme catppuccin-mocha")
  else
    vim.cmd("colorscheme gruvbox")
  end
end

-- 1. Listen for dynamic changes while Neovim is ALREADY open
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = set_theme,
})

-- 2. Wait for Neovim to fully start up BEFORE setting the initial theme
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true, -- for lualine to correctly set it's theme (does it through autocmd on background change)
  callback = set_theme,
})
