local defaultOpts = { noremap = true, silent = true }

local M = {}

M.map = function(mode, lhs, rhs, opts)
  if opts == nil then
    opts = defaultOpts
  end

  -- TODO: why not works?
  -- vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
end

M.bufmap = function(bufnr)
  return function(mode, lhs, rhs, opts)
    if opts == nil then
      opts = defaultOpts
    end
    opts.buffer = bufnr

    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- TODO: remove this shit
M.nmap = function(lhs, rhs, opts) M.map("n", lhs, rhs, opts) end

M.imap = function(lhs, rhs, opts) M.map("i", lhs, rhs, opts) end

M.vmap = function(lhs, rhs, opts) M.map("v", lhs, rhs, opts) end

M.xmap = function(lhs, rhs, opts) M.map("x", lhs, rhs, opts) end

M.tmap = function(lhs, rhs, opts) M.map("t", lhs, rhs, opts) end

M.nimap = function(lhs, rhs, opts) M.map({ "n", "i" }, lhs, rhs, opts) end

M.nvmap = function(lhs, rhs, opts) M.map({ "n", "v" }, lhs, rhs, opts) end

M.nbufmap = function(bufnr, lhs, rhs, opts) M.bufmap(bufnr)("n", lhs, rhs, opts) end

M.ibufmap = function(bufnr, lhs, rhs, opts) M.bufmap(bufnr)("i", lhs, rhs, opts) end

M.vbufmap = function(bufnr, lhs, rhs, opts) M.bufmap(bufnr)("v", lhs, rhs, opts) end

return M
