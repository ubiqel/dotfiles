local function bufmap(bufnr)
  return function(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", { buffer = bufnr, silent = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame_opts = {
        delay = 500,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = bufmap(bufnr)

        map("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "Next hunk" })

        map("n", "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "Previous hunk" })

        map({ "n", "v" }, "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
        map({ "n", "v" }, "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
        map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
        map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
        map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
        map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
        map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
        map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Diff this against HEAD" })
        map("n", "<leader>htd", gs.toggle_deleted, { desc = "Toggle deleted" })
        map("n", "<leader>htw", gs.toggle_word_diff, { desc = "Toggle word diff" })
        map("n", "<leader>htb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    keys = {
      {
        "<leader>gd",
        function()
          for _, view in ipairs(require("diffview.lib").views) do
            if view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
              vim.api.nvim_set_current_tabpage(view.tabpage)
              return
            end
          end
          require("diffview").open()
        end,
        desc = "Open diffview",
      },
    },
  },
  {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
      "m00qek/baleia.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
    },
    opts = {
      graph_style = "kitty",
    },
  },
}
