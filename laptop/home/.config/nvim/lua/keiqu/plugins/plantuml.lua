return {
  {
    "https://gitlab.com/itaranto/preview.nvim",
    version = "*",
    opts = {
      previewers_by_ft = {
        -- markdown = {
        --   name = "pandoc_wkhtmltopdf",
        --   renderer = { type = "command", opts = { cmd = { "zathura" } } },
        -- },
        plantuml = {
          name = "plantuml_svg",
          renderer = { type = "command", opts = { cmd = { "feh", "--image-bg", "white" } } },
        },
      },
      previewers = {
        plantuml_svg = {
          args = { "-pipe", "-tsvg" }, -- default has darkmode
        },
      },
      render_on_write = true,
    },
  },

  { "aklt/plantuml-syntax" },
}
