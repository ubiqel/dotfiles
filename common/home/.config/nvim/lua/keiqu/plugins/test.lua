return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-treesitter/nvim-treesitter",
      "fredrikaverpil/neotest-golang",
    },
    opts = {
      adapters = {},
      status = { virtual_text = true },
      output = { open_on_run = true },
      quickfix = {
        open = function() require("trouble").open({ mode = "quickfix", focus = false }) end,
      },
    },
    config = function(_, opts)
      opts.adapters = {
        require("neotest-golang")({
          testify_enabled = false,
          runner = "gotestsum",
          go_test_args = {
            "-v",
            "-parallel=4",
            "-count=1",
            "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
          },
        }),
      }

      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)

      opts.consumers = opts.consumers or {}
      ---@type neotest.Consumer
      opts.consumers.trouble = function(client)
        client.listeners.results = function(adapter_id, results, partial)
          if partial then
            return
          end
          local tree = assert(client:get_position(nil, { adapter = adapter_id }))

          local failed = 0
          for pos_id, result in pairs(results) do
            if result.status == "failed" and tree:get_key(pos_id) then
              failed = failed + 1
            end
          end
          vim.schedule(function()
            local trouble = require("trouble")
            if trouble.is_open() then
              trouble.refresh()
              if failed == 0 then
                trouble.close()
              end
            end
          end)
          return {}
        end
      end

      require("neotest").setup(opts)
    end,
    keys = {
      { "<leader>t", "", desc = "+test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file" },
      { "<leader>tA", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all test files" },
      { "<leader>tr", function() require("neotest").run.run() end, desc = "Run nearest" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
      {
        "<leader>to",
        function() require("neotest").output.open({ enter = true, auto_close = true }) end,
        desc = "Show output",
      },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle watch" },
    },
  },
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local coverage = require("coverage")

      coverage.setup({
        lang = {
          go = {
            auto_reload = true,
            coverage_file = "cover.cov",
          },
        },
      })

      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = { "*.go" },
        callback = function() coverage.load(false) end,
      })
    end,
    keys = {
      { "<leader>tc", function() require("coverage").toggle() end, desc = "Toggle coverage" },
    },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    keys = {
      {
        "<leader>td",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "Debug nearest",
      },
    },
  },
}
