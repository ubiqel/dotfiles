local M = {}

-- Only enable yamlls for .gitlab-ci.yaml files
M.filetypes = {} -- Empty to disable default behavior
M.root_dir = function(fname) return fname:match("%.gitlab%-ci%.ya?ml$") and vim.fn.getcwd() or nil end

return M
