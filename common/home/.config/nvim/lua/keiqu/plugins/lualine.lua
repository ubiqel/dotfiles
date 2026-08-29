return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "rmagatti/auto-session", "chrisgrieser/nvim-recorder" },
    main = "lualine",
    opts = {
      ignore_focus = { "Outline" },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          { function() return require("recorder").displaySlots() end },
          "branch",
          "diff",
          "diagnostics",
        },
        lualine_c = {
          "filename",
          { function() return require("recorder").recordingStatus() end },
        },
        lualine_x = {
          {
            function() return require("copilot_status").status_string() end,
            cnd = function() return require("copilot_status").enabled() end,
          },
          "encoding",
          "fileformat",
          "filetype",
        },
        lualine_y = {
          "progress",
        },
        lualine_z = {
          "location",
        },
      },
    },
  },

  -- {
  --   "jonahgoldwastaken/copilot-status.nvim",
  --   dependencies = { "zbirenbaum/copilot.lua" },
  --   lazy = true,
  --   event = "BufReadPost",
  --   opts = {
  --     icons = {
  --       idle = " ",
  --       offline = " ",
  --       error = " ",
  --       warning = " ",
  --       loading = " ",
  --     },
  --   },
  -- },

  {
    "chrisgrieser/nvim-recorder",
    init = function()
      -- Unbind 'q' button in normal mode to avoid conflicts with the plugin like nnoremap q <Nop>
      vim.keymap.set("n", "q", "<Nop>", { noremap = true, silent = true })
    end,
    opts = {
      mapping = {
        startStopRecording = "<leader>mr",
        playMacro = "Q",
        switchSlot = "<leader>ms",
        editMacro = "<leader>me",
        deleteAllMacros = "<leader>md",
        yankMacro = "<leader>my",
        -- ⚠️ this should be a string you don't use in insert mode during a macro
        addBreakPoint = "##",
      },
    },
  },
}
