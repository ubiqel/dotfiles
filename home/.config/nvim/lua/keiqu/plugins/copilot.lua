-- return {}
return {
  {
    "zbirenbaum/copilot.lua",
    commit = "56621aff787f78593cd2397234ec466a2d500ba0",
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
      },
    },
    keys = {
      { "<leader>cp", ":Copilot! attach<CR>", desc = "Attach Copilot" },
    },
    init = function() vim.g.copilot_proxy = os.getenv("COPILOT_PROXY_URL") end,
  },
}
