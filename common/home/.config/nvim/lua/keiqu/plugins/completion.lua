return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "windwp/nvim-autopairs", opts = { map_cr = false } },
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lua",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp_types = require("cmp.types")

      local snip_path = vim.fn.stdpath("config") .. "/lua/keiqu/snippets"
      require("luasnip/loaders/from_vscode").lazy_load({ paths = { snip_path } })
      require("luasnip/loaders/from_vscode").lazy_load()
      require("luasnip/loaders/from_lua").lazy_load({ paths = { snip_path } })

      local kind_icons = {
        Array = "",
        Boolean = "󰨙",
        Class = "",
        Codeium = "󰘦",
        Color = "",
        Control = "",
        Collapsed = "",
        Constant = "󰏿",
        Constructor = "",
        Copilot = "",
        Enum = "",
        EnumMember = "",
        Event = "",
        Field = "",
        File = "",
        Folder = "",
        Function = "󰊕",
        Interface = "",
        Key = "",
        Keyword = "",
        Method = "󰊕",
        Module = "",
        Namespace = "󰦮",
        Null = "",
        Number = "󰎠",
        Object = "",
        Operator = "",
        Package = "",
        Property = "",
        Reference = "",
        Snippet = "",
        String = "",
        Struct = "󰆼",
        Text = "",
        TypeParameter = "",
        Unit = "",
        Value = "",
        Variable = "󰀫",
      }

      local source_menu = {
        nvim_lsp = "[LSP]",
        nvim_lua = "[Nvim]",
        luasnip = "[Snippet]",
        buffer = "[Buffer]",
        path = "[Path]",
      }

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<Esc>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            vim_item.kind = kind_icons[vim_item.kind] or vim_item.kind
            vim_item.menu = source_menu[entry.source.name]
            return vim_item
          end,
        },
        completion = {
          keyword_length = 2,
          completeopt = "menu,menuone,noinsert",
          autocomplete = {
            cmp_types.cmp.TriggerEvent.InsertEnter,
            cmp_types.cmp.TriggerEvent.TextChanged,
          },
        },
        preselect = cmp.PreselectMode.Item,
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "nvim_lua" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        sorting = {
          priority_weight = 2,
          comparators = {
            cmp.config.compare.offset,
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },
        window = {
          documentation = {
            border = "solid",
            height = 200,
          },
        },
      })

      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline", keyword_length = 1 },
        }),
      })

      cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
        sources = {
          { name = "buffer" },
        },
      })

      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

      vim.opt.pumheight = 10
      vim.api.nvim_set_hl(0, "CmpItemMenu", { link = "Comment" })
    end,
  },
}
