return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Navigate left" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Navigate down" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Navigate up" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Navigate right" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Navigate previous" },
    },
  },
  "tpope/vim-dotenv",
  "tpope/vim-dispatch",
  {
    "https://gitlab.com/itaranto/preview.nvim",
    version = "*",
    opts = {
      previewers_by_ft = {
        plantuml = {
          name = "plantuml_svg",
          renderer = {
            type = "command",
            opts = { cmd = { "swayimg", "--config=viewer.scale=fit", "--config=viewer.transparency=#ffffffff" } },
          },
        },
      },
      previewers = {
        plantuml_svg = {
          args = { "-pipe", "-tsvg" },
        },
      },
      render_on_write = true,
    },
  },
  { "aklt/plantuml-syntax" },
}
