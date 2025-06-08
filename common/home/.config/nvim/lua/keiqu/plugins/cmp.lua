return {
	{ "saadparwaiz1/cmp_luasnip", dependencies = { "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets" } },
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"nvim-autopairs",
			"cmp_luasnip",
			"cmp-nvim-lsp",
			"cmp-buffer",
			"cmp-path",
			"cmp-cmdline",
		},
		config = function()
			local luasnip_ok, luasnip = pcall(require, "luasnip")
			if not luasnip_ok then
				vim.notify("Plugin 'luasnip' not found!", vim.log.levels.ERROR)
				return
			end

			local snip_loader_ok, snip_loader = pcall(require, "luasnip/loaders/from_vscode")
			if not snip_loader_ok then
				vim.notify("Snippet loader 'from_vscode' for luasnip is not found!", vim.log.levels.ERROR)
				return
			end
			snip_loader.lazy_load()

			local autopairs_ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp", vim.log.levels.ERROR)
			if not autopairs_ok then
				vim.notify("Plugin 'nvim-autopairs.completion.cmp' not found!", vim.log.levels.ERROR)
				return
			end

			local cmp_ok, cmp = pcall(require, "cmp")
			if not cmp_ok or cmp == nil then
				vim.notify("Plugin 'cmp' not found!", vim.log.levels.ERROR)
				return
			end

			local cmp_types_ok, cmp_types = pcall(require, "cmp.types")
			if not cmp_types_ok then
				vim.notify("Plugin 'cmp.types' not found!", vim.log.levels.ERROR)
				return
			end

			local function has_words_before()
				if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
					return false
				end

				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			-- Setup nvim-cmp.
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

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				style = {
					winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
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
						-- elseif luasnip.expand_or_jumpable() then
						-- 	luasnip.expand_or_jump()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						-- elseif luasnip.jumpable(-1) then
						-- 	luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				},

				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(entry, vim_item)
						local name = entry.source.name

						vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							nvim_lua = "[Nvim]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
							dadbod = "[DB]",
						})[name]

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
					-- { name = "luasnip" },
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

				experimental = {
					ghost_text = false,
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

			--set max height of items
			vim.cmd([[ set pumheight=6 ]])

			--set highlights
			local highlights = {
				CmpItemMenu = { fg = "#E1A4EB" },
			}

			for group, hl in pairs(highlights) do
				vim.api.nvim_set_hl(0, group, hl)
			end
		end,
	},
}
