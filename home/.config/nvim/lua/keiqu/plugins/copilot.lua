-- return {}
return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    cmd = "Copilot",
    opts = {
      filetypes = {
        go = true,
        lua = true,
        python = true,
        ["*"] = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
      },
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
      },
    },
    keys = {
      { "<leader>cp", ":Copilot! attach<CR>", desc = "Attach Copilot" },
    },
    init = function() vim.g.copilot_proxy = os.getenv("COPILOT_PROXY_URL") end,
  },
}
