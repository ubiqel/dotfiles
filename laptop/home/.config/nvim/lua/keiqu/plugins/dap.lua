local nmap = require("keiqu.keymaps").nmap

return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      dap.configurations.go = {
        {
          type = "go",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          dlvToolPath = vim.fn.exepath("dlv"),
        },
      }

      vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })

      nmap("<F1>", function() dap.step_over() end)
      nmap("<F2>", function() dap.step_into() end)
      nmap("<F3>", function() dap.step_out() end)
      nmap("<F5>", function() dap.continue() end)
      nmap("<F6>", function() dap.pause() end)
      nmap("<F8>", function() dap.up() end)
      nmap("<F9>", function() dap.down() end)
      nmap("<F10>", function() dap.step_back() end)
      nmap("<leader>db", function() dap.toggle_breakpoint() end)
      nmap("<leader>dB", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end)
      nmap("<leader>dp", function() dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end)
      nmap("<leader>dx", function() dap.terminate() end)
      nmap("<leader>dc", function() dap.clear_breakpoints() end)
      nmap("<leader>dr", function() dap.repl.open() end)
      nmap("<leader>dl", function() dap.run_last() end)
    end,
  },

  {
    "leoluz/nvim-dap-go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
    init = function() nmap("<leader>dt", ":lua require('dap-go').debug_test()<CR>") end,
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      dapui.setup({
        layouts = {
          {
            elements = {
              {
                id = "scopes",
                size = 0.25,
              },
              {
                id = "breakpoints",
                size = 0.25,
              },
              {
                id = "stacks",
                size = 0.25,
              },
              {
                id = "watches",
                size = 0.25,
              },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              {
                id = "console",
                size = 0.5,
              },
              {
                id = "repl",
                size = 0.5,
              },
            },
            position = "bottom",
            size = 10,
          },
        },
        mappings = {
          edit = "e",
          expand = { "<CR>", "o" },
          open = "i",
          remove = "d",
          repl = "r",
          toggle = "t",
        },
      })

      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      nmap("<leader>do", function() dapui.toggle() end)
    end,
  },

  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    config = true,
  },
}
