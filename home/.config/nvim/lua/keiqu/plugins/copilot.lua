return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      filetypes = {
        go = true,
        yaml = true,
        markdown = true,
        sh = function()
          if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "^%.env.*") then
            -- disable for .env files
            return false
          end

          return true
        end,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
      },
      panel = {
        enabled = true,
        auto_refresh = true,
      },
    },
    keys = {
      { "<leader>cp", ":Copilot enable<CR>", desc = "Enable Copilot" },
    },
    init = function() vim.g.copilot_proxy = os.getenv("COPILOT_PROXY_URL") end,
  },
}
