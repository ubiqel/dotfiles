return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "chrisgrieser/nvim-recorder",
    },
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
  {
    "chrisgrieser/nvim-recorder",
    init = function() vim.keymap.set("n", "q", "<Nop>", { noremap = true, silent = true }) end,
    opts = {
      mapping = {
        startStopRecording = "<leader>mr",
        playMacro = "Q",
        switchSlot = "<leader>ms",
        editMacro = "<leader>me",
        deleteAllMacros = "<leader>md",
        yankMacro = "<leader>my",
        addBreakPoint = "##",
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
    },
    keys = {
      {
        "<S-Enter>",
        function() require("noice").redirect(vim.fn.getcmdline()) end,
        mode = "c",
        desc = "Redirect command line",
      },
      { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice: last message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice: history" },
      { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice: all" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Noice: dismiss all" },
      { "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice: picker" },
    },
  },
  {
    "stevearc/dressing.nvim",
    opts = {},
  },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "LspAttach",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP definitions/references (Trouble)",
      },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location list (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list (Trouble)" },
    },
  },
  {
    "RRethy/vim-illuminate",
    config = function()
      vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "LspReferenceText" })
      vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "LspReferenceRead" })
      vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })

      require("illuminate").configure({
        providers = { "lsp", "treesitter" },
        filetypes_denylist = { "netrw" },
      })
    end,
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/trouble.nvim" },
    opts = {
      search = {
        args = {
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--trim",
          "--hidden",
          "-g=!vendor/",
          "-g=!node_modules/",
          "-g=!.venv/",
          "-g=!venv/",
          "-g=!.mypy_cache/",
          "-g=!.linter-cache/",
          "-g=!.git/",
        },
      },
    },
    keys = {
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo comments (Trouble)" },
    },
    ft = {
      "markdown",
      "go",
      "python",
      "helm",
      "yaml",
      "lua",
      "javascript",
      "typescript",
      "java",
      "bash",
      "fish",
      "html",
      "css",
    },
  },
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      user_default_options = { css = true },
      filetypes = {
        "css",
        "html",
        "javascript",
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 500,
      spec = {
        { "<leader><tab>", group = "tabs" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunks" },
        { "<leader>l", group = "LSP" },
        { "<leader>m", group = "macros" },
        { "<leader>r", group = "rename/refactor" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "test" },
        { "<leader>x", group = "diagnostics" },
      },
    },
  },
}
