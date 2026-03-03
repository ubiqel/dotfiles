local M = {}

M.setup = function()
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }

  for _, sign in pairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end

  local config = {
    virtual_text = false,
    signs = { -- TODO: check that it does something
      active = signs,
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal", -- TODO: what styles there are?
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  }

  vim.diagnostic.config(config)

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
    width = 60,
    max_width = 120,
  })

  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "rounded",
    width = 60,
    max_width = 120,
  })

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
    width = 60,
    max_width = 120,
  })

  vim.lsp.inlay_hint.enable(true)
end

local function add_keymaps(bufnr)
  local nmap = require("keiqu.keymaps").nbufmap
  local vmap = require("keiqu.keymaps").vbufmap
  local imap = require("keiqu.keymaps").ibufmap

  -- TODO: use documentSymbol with telescope
  -- TODO: use lsp_dynamic_workspace_symbols with telescope
  nmap(bufnr, "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
  nmap(bufnr, "gd", "<cmd>lua require('telescope.builtin').lsp_definitions()<CR>")
  nmap(bufnr, "grt", "<cmd>lua require('telescope.builtin').lsp_type_definitions()<CR>")
  nmap(bufnr, "gri", "<cmd>lua require('telescope.builtin').lsp_implementations()<cr>")
  nmap(bufnr, "gre", "<cmd>lua require('telescope.builtin').lsp_references()<CR>")

  nmap(bufnr, "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
  nmap(bufnr, "<C-s>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
  imap(bufnr, "<C-s>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")

  nmap(bufnr, "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>")

  nmap(bufnr, "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>")
  vmap(bufnr, "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>")

  nmap(bufnr, "<leader>lc", "<cmd>lua vim.lsp.codelens.run()<cr>")
  vmap(bufnr, "<leader>lc", "<cmd>lua vim.lsp.codelens.run()<cr>")

  nmap(bufnr, "<leader>lC", "<cmd>lua vim.lsp.codelens.refresh()<cr>")
  vmap(bufnr, "<leader>lC", "<cmd>lua vim.lsp.codelens.refresh()<cr>")
  -- { "<leader>cA", LazyVim.lsp.action.source, desc = "Source Action", has = "codeAction" },

  nmap(bufnr, "<leader>lf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>")
  nmap(bufnr, "]d", "<cmd>lua vim.diagnostic.goto_next({buffer=0})<cr>")
  nmap(bufnr, "[d", "<cmd>lua vim.diagnostic.goto_prev({buffer=0})<cr>")

  nmap(bufnr, "]e", function() vim.diagnostic.goto_next({ buffer = 0, severity = vim.diagnostic.severity.ERROR }) end)
  nmap(bufnr, "[e", function() vim.diagnostic.goto_prev({ buffer = 0, severity = vim.diagnostic.severity.ERROR }) end)
  nmap(bufnr, "<leader>lp", "<cmd>lua vim.diagnostic.open_float()<CR>")

  -- nmap(bufnr, "<leader>vr", "<cmd>LspRestart<CR>")

  -- nmap(bufnr, "<leader>uh", "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>")
  nmap(bufnr, "<leader>lh", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
  end)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "LspAttached",
  once = true,
  callback = vim.lsp.codelens.refresh,
})

M.on_attach = function(_, bufnr)
  add_keymaps(bufnr)

  -- refresh codelens on TextChanged and InsertLeave as well
  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    buffer = bufnr,
    callback = vim.lsp.codelens.refresh,
  })

  vim.api.nvim_exec_autocmds("User", { pattern = "LspAttached" })
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem.snippetSupport = true
local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not ok then
  vim.notify("Plugin 'cmp_nvim_lsp' not found!")
  return M
end

M.capabilities = cmp_nvim_lsp.default_capabilities(M.capabilities)

M.implementation = function()
  -- TODO: use telescope
  local params = vim.lsp.util.make_position_params()

  vim.lsp.buf_request(0, "textDocument/implementation", params, function(err, result, ctx, config)
    local bufnr = ctx.bufnr
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")

    -- In go code, I do not like to see any mocks for impls
    if ft == "go" then
      local new_result = vim.tbl_filter(function(v) return not string.find(v.uri, "_test") end, result)

      if #new_result > 0 then
        result = new_result
      end
    end

    vim.lsp.handlers["textDocument/implementation"](err, result, ctx, config)
    vim.cmd([[normal! zz]])
  end)
end

return M
