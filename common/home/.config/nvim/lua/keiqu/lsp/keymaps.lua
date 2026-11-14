local M = {}

local function has(bufnr, method)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client:supports_method(method, bufnr) then
      return true
    end
  end
  return false
end

local function map(bufnr, mode, lhs, rhs, desc, method)
  if method and not has(bufnr, method) then
    return
  end

  vim.keymap.set(mode, lhs, rhs, {
    buffer = bufnr,
    desc = desc,
    silent = true,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("keiqu_lsp_attach", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      local bufnr = args.buf

      map(bufnr, "n", "gD", vim.lsp.buf.declaration, "Goto declaration", "textDocument/declaration")
      map(
        bufnr,
        "n",
        "gd",
        function() require("telescope.builtin").lsp_definitions() end,
        "Goto definition",
        "textDocument/definition"
      )
      map(
        bufnr,
        "n",
        "grt",
        function() require("telescope.builtin").lsp_type_definitions() end,
        "Goto type definition",
        "textDocument/typeDefinition"
      )
      map(
        bufnr,
        "n",
        "gri",
        function() require("telescope.builtin").lsp_implementations() end,
        "Goto implementation",
        "textDocument/implementation"
      )
      map(
        bufnr,
        "n",
        "gre",
        function() require("telescope.builtin").lsp_references() end,
        "Goto references",
        "textDocument/references"
      )

      if vim.bo[bufnr].filetype == "cs" then
        map(
          bufnr,
          "n",
          "gd",
          function() require("omnisharp_extended").telescope_lsp_definitions() end,
          "Goto definition",
          "textDocument/definition"
        )
      end

      map(
        bufnr,
        "n",
        "K",
        function() vim.lsp.buf.hover({ border = "rounded", max_width = 120 }) end,
        "Hover documentation",
        "textDocument/hover"
      )

      map(
        bufnr,
        { "n", "i" },
        "<C-s>",
        function() vim.lsp.buf.signature_help({ border = "rounded", max_width = 120 }) end,
        "Signature help",
        "textDocument/signatureHelp"
      )

      map(bufnr, "n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol", "textDocument/rename")
      map(bufnr, { "n", "x" }, "<leader>la", vim.lsp.buf.code_action, "Code action", "textDocument/codeAction")
      map(bufnr, { "n", "x" }, "<leader>lc", vim.lsp.codelens.run, "Run codelens", "textDocument/codeLens")
      map(bufnr, { "n", "x" }, "<leader>lC", vim.lsp.codelens.refresh, "Refresh codelens", "textDocument/codeLens")
      map(
        bufnr,
        "n",
        "<leader>lf",
        function() vim.lsp.buf.format({ async = true }) end,
        "Format buffer",
        "textDocument/formatting"
      )

      map(bufnr, "n", "]d", function() vim.diagnostic.jump({ count = 1, bufnr = bufnr }) end, "Next diagnostic")
      map(bufnr, "n", "[d", function() vim.diagnostic.jump({ count = -1, bufnr = bufnr }) end, "Previous diagnostic")
      map(
        bufnr,
        "n",
        "]e",
        function() vim.diagnostic.jump({ count = 1, bufnr = bufnr, severity = vim.diagnostic.severity.ERROR }) end,
        "Next error"
      )
      map(
        bufnr,
        "n",
        "[e",
        function() vim.diagnostic.jump({ count = -1, bufnr = bufnr, severity = vim.diagnostic.severity.ERROR }) end,
        "Previous error"
      )
      map(
        bufnr,
        "n",
        "<leader>lp",
        function() vim.diagnostic.open_float({ border = "rounded" }) end,
        "Line diagnostics"
      )
      map(bufnr, "n", "<leader>lr", "<cmd>LspRestart<cr>", "Restart LSP")
      map(bufnr, "n", "<leader>li", "<cmd>LspInfo<cr>", "LSP info")
      map(bufnr, "n", "<leader>lh", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
      end, "Toggle inlay hints", "textDocument/inlayHint")

      if not vim.b[bufnr].keiqu_lsp_inlay and has(bufnr, "textDocument/inlayHint") and vim.bo[bufnr].buftype == "" then
        vim.b[bufnr].keiqu_lsp_inlay = true
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end

      if not vim.b[bufnr].keiqu_lsp_codelens and has(bufnr, "textDocument/codeLens") then
        vim.b[bufnr].keiqu_lsp_codelens = true
        vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
          buffer = bufnr,
          callback = function() vim.lsp.codelens.refresh({ bufnr = bufnr }) end,
        })
      end
    end,
  })
end

return M
