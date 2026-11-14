local function git_pull_branch(prompt_bufnr)
  local utils = require("telescope.utils")
  local action_state = require("telescope.actions.state")

  local cwd = action_state.get_current_picker(prompt_bufnr).cwd
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection("git_pull_branch")
    return
  end

  local branch = selection.value
  local _, ret, stderr =
    utils.get_os_command_output({ "git", "fetch", "origin", string.format("%s:%s", branch, branch) }, cwd)
  if ret ~= 0 then
    utils.notify("git_pull_branch", {
      msg = string.format("Error when pulling branch: %s. Git returned: '%s'", branch, table.concat(stderr, " ")),
      level = "ERROR",
    })
    return
  end

  utils.notify("git_pull_branch", {
    msg = string.format("Pulled branch '%s'", branch),
    level = "INFO",
  })
end

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
      {
        "<leader>fs",
        function() require("telescope.builtin").lsp_dynamic_workspace_symbols() end,
        desc = "Workspace symbols",
      },
      { "<leader>gs", function() require("telescope.builtin").git_status() end, desc = "Git status" },
      { "<leader>gb", function() require("telescope.builtin").git_branches() end, desc = "Git branches" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_layout = require("telescope.actions.layout")
      local action_state = require("telescope.actions.state")

      local delete_buffer_force = function(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:delete_selection(function(selection)
          local ok_delete = pcall(vim.api.nvim_buf_delete, selection.bufnr, { force = true })
          return ok_delete
        end)
      end

      local delete_all_buffers = function(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local entries = current_picker.manager:iter()

        for entry in entries do
          if entry.bufnr == vim.api.nvim_get_current_buf() then
            goto continue
          end

          local ok_delete = pcall(vim.api.nvim_buf_delete, entry.bufnr, { force = true })
          if not ok_delete then
            vim.notify("Error deleting buffer: " .. entry.bufnr, vim.log.levels.ERROR)
          end

          ::continue::
        end

        actions.close(prompt_bufnr)
      end

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<M-p>"] = action_layout.toggle_preview,
              ["<M-m>"] = action_layout.toggle_mirror,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
          color_devicons = true,
          layout_strategy = "flex",
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
            "--hidden",
            "-g=!vendor/",
            "-g=!.venv/",
            "-g=!venv/",
            "-g=!.mypy_cache/",
            "-g=!.linter-cache/",
            "-g=!node_modules/",
            "--no-ignore-vcs",
          },
        },
        pickers = {
          find_files = {
            theme = "dropdown",
            previewer = false,
            path_display = { "filename_first" },
            find_command = {
              "fd",
              "--hidden",
              "--type",
              "f",
              "--strip-cwd-prefix",
              "-E",
              "vendor/",
              "-E",
              "venv/",
              "-E",
              ".git",
              "-E",
              ".mypy_cache",
              "-E",
              ".linter-cache",
              "-E",
              "node_modules/",
              "--no-ignore-vcs",
              "-i",
              "-g",
            },
          },
          buffers = {
            theme = "dropdown",
            previewer = false,
            sort_mru = true,
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
                ["<C-r>"] = delete_buffer_force,
                ["<C-t>"] = delete_all_buffers,
              },
              n = {
                ["<C-d>"] = actions.delete_buffer,
                ["<C-r>"] = delete_buffer_force,
                ["<C-t>"] = delete_all_buffers,
              },
            },
          },
          help_tags = {
            theme = "dropdown",
            previewer = false,
          },
          git_status = {
            theme = "dropdown",
            previewer = false,
          },
          git_branches = {
            theme = "dropdown",
            previewer = false,
            mappings = {
              n = {
                ["<C-d>"] = actions.git_delete_branch,
                ["<C-r>"] = actions.git_rebase_branch,
                ["<C-p>"] = git_pull_branch,
                ["<CR>"] = actions.git_switch_branch,
                ["s"] = actions.toggle_selection,
              },
              i = {
                ["<C-d>"] = actions.git_delete_branch,
                ["<C-r>"] = actions.git_rebase_branch,
                ["<C-p>"] = git_pull_branch,
                ["<CR>"] = actions.git_switch_branch,
              },
            },
          },
        },
      })

      pcall(telescope.load_extension, "fzf")
    end,
  },
}
