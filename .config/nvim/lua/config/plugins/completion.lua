-- blink.cmp: completion from LSP, paths, snippets (friendly-snippets) and the buffer, with a
-- native fuzzy matcher. Copilot suggestions stay inline (Ctrl+a accepts, see copilot.lua).
return {
	"saghen/blink.cmp",
	version = "1.*", -- release builds ship the prebuilt fuzzy matcher
	event = { "InsertEnter", "CmdlineEnter" },
	dependencies = { "rafamadriz/friendly-snippets" },
	opts = {
		keymap = {
			preset = "default", -- Ctrl+Space open, Ctrl+y accept, Ctrl+n/p move, Ctrl+b/f scroll docs
			["<C-j>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["<C-e>"] = { "hide", "fallback" },
		},
		completion = {
			list = { selection = { preselect = false, auto_insert = false } },
			menu = { border = "rounded" },
			documentation = { auto_show = true, window = { border = "rounded" } },
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
			providers = {
				lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
}
