return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "windwp/nvim-autopairs", config = true },
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

      local function has_words_before()
        if vim.bo.buftype == "prompt" then
          return false
        end

        local cursor = vim.api.nvim_win_get_cursor(0)
        local line, col = cursor[1], cursor[2]
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

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
        mapping = {
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
          ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
          ["<C-e>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
          }),
          ["<CR>"] = cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        },
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
          autocomplete = {
            cmp_types.cmp.TriggerEvent.InsertEnter,
            cmp_types.cmp.TriggerEvent.TextChanged,
          },
        },
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

      vim.opt.pumheight = 6
      vim.api.nvim_set_hl(0, "CmpItemMenu", { link = "Comment" })
    end,
  },
}
