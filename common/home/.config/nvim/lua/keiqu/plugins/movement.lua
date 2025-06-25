return {
  -- {
  --   "folke/flash.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     modes = {
  --       search = {
  --         enabled = false,
  --       },
  --     },
  --     char = {
  --       config = function(opts)
  --         -- autohide flash when in operator-pending mode
  --         opts.autohide = opts.autohide or (vim.fn.mode(true):find("no") and vim.v.operator == "y")

  --         -- disable jump labels when not enabled, when using a count,
  --         -- or when recording/executing registers
  --         opts.jump_labels = opts.jump_labels
  --           and vim.v.count == 0
  --           and vim.fn.reg_executing() == ""
  --           and vim.fn.reg_recording() == ""

  --         -- Show jump labels only in operator-pending mode
  --         -- opts.jump_labels = vim.v.count == 0 and vim.fn.mode(true):find("o")
  --       end,
  --     },
  --   },
  --   keys = {
  --     { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
  --     { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  --     { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
  --     { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  --     { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  --   },
  -- },
}
