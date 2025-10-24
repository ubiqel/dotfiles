return {
  -- {
  --   "supermaven-inc/supermaven-nvim",
  --   config = function()
  --     require("supermaven-nvim").setup({
  --       keymaps = {
  --         accept_suggestion = "<M-l>",
  --         clear_suggestion = "<C-]>",
  --         accept_word = "<C-[>",
  --       },
  --       color = {
  --         suggestion_color = "#a9a9a9",
  --         cterm = 244,
  --       },
  --       log_level = "info", -- set to "off" to disable logging completely
  --       disable_inline_completion = false, -- disables inline completion for use with cmp
  --       disable_keymaps = true, -- disables built in keymaps for use
  --       condition = function()
  --         return false

  --         -- local ft = vim.bo.filetype
  --         -- local allowed_filetypes = { "go", "lua", "python", "javascript", "typescript", "java", "c", "cpp", "rust" }
  --         -- for _, v in ipairs(allowed_filetypes) do
  --         --   if ft == v then
  --         --     return true
  --         --   end
  --         -- end

  --         -- return true
  --       end,
  --     })

  --     local completion_preview = require("supermaven-nvim.completion_preview")
  --     vim.keymap.set("i", "<M-l>", completion_preview.on_accept_suggestion, { noremap = true, silent = true })
  --     vim.keymap.set("i", "<c-j>", completion_preview.on_accept_suggestion_word, { noremap = true, silent = true })
  --     -- vim.keymap.set("i", "<c-]>", completion_preview., { noremap = true, silent = true })
  --   end,
  -- },
}
