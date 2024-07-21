require("keiqu.general")
require("keiqu.globals")

-- Format
require("keiqu.format.lua")
require("keiqu.format.trim")
-- require("keiqu.format.json")
require("keiqu.format.go")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("keiqu.plugins", {
  dev = { path = "~/code" },
})

vim.cmd([[colorscheme tokyonight-storm]])
