return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-buffer", -- source for text in buffer
			"hrsh7th/cmp-path", -- source for file system paths
			{
				"L3MON4D3/LuaSnip",
				-- follow latest release.
				version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
				-- install jsregexp (optional!).
				build = "make install_jsregexp",
			},
			"saadparwaiz1/cmp_luasnip", -- for autocompletion
			"rafamadriz/friendly-snippets", -- useful snippets
			"onsails/lspkind.nvim", -- vs-code like pictograms
		},
		config = function()
			local cmp = require("cmp")

			local luasnip = require("luasnip")

			local lspkind = require("lspkind")

			-- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,preview,noselect",
				},
				snippet = { -- configure how nvim-cmp interacts with snippet engine
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
					["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
					["<C-n>"] = cmp.mapping.select_next_item(), -- next suggestion
					["<C-p>"] = cmp.mapping.select_prev_item(), -- previous suggestion
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
					["<C-e>"] = cmp.mapping.abort(), -- close completion window
					["<CR>"] = cmp.mapping.confirm({ select = false }),
				}),
				-- sources for autocompletion
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" }, -- snippets
					{ name = "buffer" }, -- text within current buffer
					{ name = "path" }, -- file system paths
				}),

-- Window configuration with Tokyo Night colors
				window = {
					completion = {
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
						col_offset = -3,
						side_padding = 0,
						border = "rounded",
						winblend = 0, -- Use theme transparency
					},
					documentation = {
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
						border = "rounded",
						winblend = 0, -- Use theme transparency
					},
				},

				-- configure lspkind for vs-code like pictograms in completion menu
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(entry, vim_item)
						local kind_icons = {
							Text = "󰉣 ",
							Method = "󰆕 ",
							Function = "󰊕 ",
							Constructor = "󰆄 ",
							Field = "󰇽 ",
							Variable = "󰂡 ",
							Class = "󰠱 ",
							Interface = "󰜰 ",
							Module = "󰏗 ",
							Property = "󰜢 ",
							Unit = "󰑭 ",
							Value = "󰎠 ",
							Enum = "󰕳 ",
							Keyword = "󰌋 ",
							Snippet = "󰌪 ",
							Color = "󰏘 ",
							File = "󰈙 ",
							Reference = "󰈽 ",
							Folder = "󰉋 ",
							EnumMember = "󰕳 ",
							Constant = "󰏿 ",
							Struct = "󰙅 ",
							Event = "󰅴 ",
							Operator = "󰆕 ",
							TypeParameter = "󰅩 ",
						}
						-- Kind icons
						vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind] or "", vim_item.kind)
						-- Menu
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							luasnip = "[Snip]",
							buffer = "[Buf]",
							path = "[Path]",
						})[entry.source.name] or ""
						-- Max width for the label
						vim_item.abbr = string.sub(vim_item.abbr, 1, 50)
						return vim_item
					end,
				},
			})
		end,
	},
}

