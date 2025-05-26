local git_pull_branch = function(prompt_bufnr)
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
      "nvim-telescope/telescope-ui-select.nvim",
      {
        "nvim-telescope/telescope-frecency.nvim",
        version = "*",
        config = function() end,
      },
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local ok, telescope = pcall(require, "telescope")
      if not ok then
        vim.notify("Plugin 'telescope' not found!", vim.log.levels.ERROR)
        return
      end

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
          -- if it's current buffer then keep it
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

      telescope.load_extension("frecency")

      telescope.setup({
        externsions = {
          frecency = {
            auto_validate = true,
            matcher = "fuzzy",
            path_display = { "filename_first" },
            hide_current_buffer = true,
            ignore_patterns = { "*.git/*", "*/tmp/*", "term://*", "*.mypy_cache/*", "*.venv/*", "*venv/*", "*vendor/*" },
          },
        },
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
            "--no-ignore-vcs",
          },
        },
        pickers = {
          find_files = {
            theme = "dropdown",
            previewer = false,
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
              "--no-ignore-vcs",
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
    end,
  },
}
