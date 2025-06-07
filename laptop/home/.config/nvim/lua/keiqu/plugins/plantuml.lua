return {
  {
    "https://gitlab.com/itaranto/preview.nvim",
    version = "*",
    opts = {
      previewers_by_ft = {
        plantuml = {
          name = "plantuml_svg",
          -- renderer = { type = "imv" }, -- can't use it if display scaling is set: svg centers at the left upper corner
          renderer = {
            type = "command",
            opts = { cmd = { "swayimg", "--config=viewer.scale=fit", "--config=viewer.transparency=#ffffffff" } },
          },
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
