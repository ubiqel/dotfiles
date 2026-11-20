local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazylua = lazypath .. "/lua/lazy/init.lua"
local uv = vim.uv or vim.loop

-- Check for lazy's entrypoint, not just the directory: an interrupted clone can
-- leave lazypath behind with no checked out files, which makes the bootstrap a
-- no-op and breaks `require("lazy")`.
if not uv.fs_stat(lazylua) then
  vim.fn.delete(lazypath, "rf")
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 or not uv.fs_stat(lazylua) then
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
