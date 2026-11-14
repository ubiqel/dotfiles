return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })

      local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true }) end

      map("<F1>", function() dap.step_over() end, "DAP: step over")
      map("<F2>", function() dap.step_into() end, "DAP: step into")
      map("<F3>", function() dap.step_out() end, "DAP: step out")
      map("<F5>", function() dap.continue() end, "DAP: continue")
      map("<F6>", function() dap.pause() end, "DAP: pause")
      map("<F8>", function() dap.up() end, "DAP: up")
      map("<F9>", function() dap.down() end, "DAP: down")
      map("<F10>", function() dap.step_back() end, "DAP: step back")
      map("<leader>db", function() dap.toggle_breakpoint() end, "DAP: toggle breakpoint")
      map(
        "<leader>dB",
        function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        "DAP: conditional breakpoint"
      )
      map(
        "<leader>dp",
        function() dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end,
        "DAP: log point"
      )
      map("<leader>dx", function() dap.terminate() end, "DAP: terminate")
      map("<leader>dc", function() dap.clear_breakpoints() end, "DAP: clear breakpoints")
      map("<leader>dl", function() dap.run_last() end, "DAP: run last")
    end,
  },
  {
    "igorlfs/nvim-dap-view",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      winbar = {
        default_section = "scopes",
      },
    },
    init = function()
      local dap, dv = require("dap"), require("dap-view")
      dap.listeners.before.attach["dap-view-config"] = function() dv.open() end
      dap.listeners.before.launch["dap-view-config"] = function() dv.open() end

      vim.keymap.set("n", "<leader>do", function() dv.toggle() end, { desc = "DAP: toggle view", silent = true })
    end,
  },
}
