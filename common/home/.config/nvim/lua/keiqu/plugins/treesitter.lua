-- jinja/jinja_inline are intentionally omitted: the upstream queries do not
-- currently parse with the installed parser.
local parsers = {
  "go",
  "gomod",
  "gowork",
  "gosum",
  "python",
  "lua",
  "luadoc",
  "vim",
  "vimdoc",
  "bash",
  "fish",
  "json",
  "yaml",
  "toml",
  "markdown",
  "markdown_inline",
  "html",
  "css",
  "javascript",
  "typescript",
  "tsx",
  "templ",
  "c_sharp",
  "gdscript",
  "rust",
  "odin",
  "java",
  "diff",
  "gitcommit",
  "gitignore",
  "git_config",
  "query",
  "regex",
  "xml",
  "dockerfile",
  "make",
  "c",
  "cpp",
  "helm",
  "gotmpl",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup()

      local installed = {}
      for _, parser in ipairs(ts.get_installed("parsers")) do
        installed[parser] = true
      end

      local missing = vim.tbl_filter(function(parser) return not installed[parser] end, parsers)

      if #missing > 0 then
        ts.install(missing)
      end
    end,
  },
}
