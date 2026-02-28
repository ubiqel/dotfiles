return {
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<M-l>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-[>",
        },
        color = {
          suggestion_color = "#a9a9a9",
          cterm = 244,
        },
        log_level = "info", -- set to "off" to disable logging completely
        disable_inline_completion = false, -- disables inline completion for use with cmp
        ignore_filetypes = { "sh" },
        disable_keymaps = true, -- disables built in keymaps for use
      })

      local completion_preview = require("supermaven-nvim.completion_preview")
      vim.keymap.set("i", "<M-l>", completion_preview.on_accept_suggestion, { noremap = true, silent = true })
      vim.keymap.set("i", "<c-j>", completion_preview.on_accept_suggestion_word, { noremap = true, silent = true })
      -- vim.keymap.set("i", "<c-]>", completion_preview., { noremap = true, silent = true })
    end,
  },
  {
    "ThePrimeagen/99",
    config = function()
      local _99 = require("99")

      -- For logging that is to a file if you wish to trace through requests
      -- for reporting bugs, i would not rely on this, but instead the provided
      -- logging mechanisms within 99.  This is for more debugging purposes
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)
      _99.setup({
        provider = _99.OpenCodeProvider,
        model = "openai/gpt-5.2-codex",
        logger = {
          level = _99.DEBUG,
          path = "/tmp/" .. basename .. ".99.debug",
          print_on_error = true,
        },

        completion = {
          files = {
            enabled = true,
            exclude = { ".env", ".env.*", "node_modules", ".git", ".lint-cache" },
          },

          source = "cmp",
        },

        --- WARNING: if you change cwd then this is likely broken
        --- ill likely fix this in a later change
        ---
        --- md_files is a list of files to look for and auto add based on the location
        --- of the originating request.  That means if you are at /foo/bar/baz.lua
        --- the system will automagically look for:
        --- /foo/bar/AGENT.md
        --- /foo/AGENT.md
        --- assuming that /foo is project root (based on cwd)
        md_files = {
          "AGENT.md",
        },
      })

      vim.keymap.set("v", "<leader>9v", function() _99.visual() end)
      vim.keymap.set("n", "<leader>9x", function() _99.stop_all_requests() end)
      vim.keymap.set("n", "<leader>9s", function() _99.search() end)

      vim.keymap.set("n", "<leader>9d", function()
        --- this function could be used to auto debug your project
        _99.search({
          additional_prompt = [[
run `task test` and debug the test failures and provide me a comprehensive set of steps where
the tests are breaking ]],
        })
      end)

      vim.keymap.set("n", "<leader>9p", function() require("99.extensions.telescope").select_provider() end)
      vim.keymap.set("n", "<leader>9m", function() require("99.extensions.telescope").select_model() end)
    end,
  },
}
