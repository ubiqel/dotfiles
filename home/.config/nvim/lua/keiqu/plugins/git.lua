return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame_opts = {
        delay = 500,
      },

      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = require("keiqu.keymaps").bufmap(bufnr)

        map("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true })

        map("n", "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true })

        -- Actions
        map({ "n", "v" }, "<leader>hs", gs.stage_hunk)
        map({ "n", "v" }, "<leader>hr", gs.reset_hunk)
        map("n", "<leader>hS", gs.stage_buffer)
        map("n", "<leader>hu", gs.undo_stage_hunk)
        map("n", "<leader>hR", gs.reset_buffer)
        map("n", "<leader>hp", gs.preview_hunk)
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end)
        map("n", "<leader>hd", gs.diffthis)
        map("n", "<leader>hD", function() gs.diffthis("~") end)
        map("n", "<leader>htd", gs.toggle_deleted)
        map("n", "<leader>htw", gs.toggle_word_diff)
        map("n", "<leader>htb", gs.toggle_current_line_blame)

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
      end,
    },
  },
  {
    "tpope/vim-fugitive",
    config = function() vim.g.fugitive_gitlab_domains = { "https://gitlab.2gis.ru" } end,
    dependencies = { "shumphrey/fugitive-gitlab.vim" },
  },
  {
    "sindrets/diffview.nvim",
    init = function()
      local nmap = require("keiqu.keymaps").nmap
      nmap("<leader>gd", function() require("diffview").open() end)
    end,
  },
  {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "stevearc/dressing.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    enabled = true,
    build = function() require("gitlab.server").build(true) end, -- Builds the Go binary
    opts = {
      config_path = vim.fn.expand("$HOME/work"),
      discussion_tree = {
        position = "bottom",
      },
    },
    init = function()
      local gitlab = require("gitlab")

      vim.keymap.set("n", "glr", gitlab.review)
      vim.keymap.set("n", "gls", gitlab.summary)
      vim.keymap.set("n", "glA", gitlab.approve)
      vim.keymap.set("n", "glR", gitlab.revoke)
      vim.keymap.set("n", "glc", gitlab.create_comment)
      vim.keymap.set("v", "glc", gitlab.create_multiline_comment)
      vim.keymap.set("v", "glC", gitlab.create_comment_suggestion)
      vim.keymap.set("n", "glO", gitlab.create_mr)
      vim.keymap.set("n", "glm", gitlab.move_to_discussion_tree_from_diagnostic)
      vim.keymap.set("n", "gln", gitlab.create_note)
      vim.keymap.set("n", "gld", gitlab.toggle_discussions)
      vim.keymap.set("n", "glaa", gitlab.add_assignee)
      vim.keymap.set("n", "glad", gitlab.delete_assignee)
      vim.keymap.set("n", "glla", gitlab.add_label)
      vim.keymap.set("n", "glld", gitlab.delete_label)
      vim.keymap.set("n", "glra", gitlab.add_reviewer)
      vim.keymap.set("n", "glrd", gitlab.delete_reviewer)
      vim.keymap.set("n", "glp", gitlab.pipeline)
      vim.keymap.set("n", "glo", gitlab.open_in_browser)
      vim.keymap.set("n", "glM", gitlab.merge)
    end,
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      git_services = {
        ["github.com"] = "https://github.com/${owner}/${repository}/compare/${branch_name}?expand=1",
        ["bitbucket.org"] = "https://bitbucket.org/${owner}/${repository}/pull-requests/new?source=${branch_name}&t=1",
        ["gitlab.com"] = "https://gitlab.com/${owner}/${repository}/merge_requests/new?merge_request[source_branch]=${branch_name}",
        ["gitlab.2gis.ru"] = "https://gitlab.2gis.ru/${owner}/${repository}/merge_requests/new?merge_request[source_branch]=${branch_name}",
        ["azure.com"] = "https://dev.azure.com/${owner}/_git/${repository}/pullrequestcreate?sourceRef=${branch_name}&targetRef=${target}",
      },
    },
    config = true,
  },
}
