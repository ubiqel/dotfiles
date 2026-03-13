return {
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      user_default_options = { css = true },
      filetypes = {
        "css",
        "html",
        "javascript",
        -- "templ",
      },
    },
  },
}
