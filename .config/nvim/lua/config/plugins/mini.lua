-- mini.nvim: text objects, pairs, surround, moving lines, git diff signs, colour and TODO
-- highlights, icons. One plugin instead of vim-move, colorizer, todo-comments and devicons.
return {
	"echasnovski/mini.nvim",
	version = false,
	config = function()
		local ai = require("mini.ai")
		ai.setup({
			custom_textobjects = { -- af/if, ac/ic from treesitter (queries: nvim-treesitter-textobjects)
				f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
				c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
			},
		})
		require("mini.pairs").setup()
		require("mini.surround").setup()
		require("mini.move").setup() -- Alt+h/j/k/l moves the line or selection

		require("mini.diff").setup()
		vim.keymap.set("n", "<leader>do", function()
			MiniDiff.toggle_overlay(0)
		end, { desc = "Toggle diff overlay" })

		local hipatterns = require("mini.hipatterns")
		local word = function(w)
			return "%f[%w]()" .. w .. "()%f[%W]"
		end
		hipatterns.setup({
			highlighters = {
				fixme = { pattern = word("FIXME"), group = "MiniHipatternsFixme" },
				hack = { pattern = word("HACK"), group = "MiniHipatternsHack" },
				todo = { pattern = word("TODO"), group = "MiniHipatternsTodo" },
				note = { pattern = word("NOTE"), group = "MiniHipatternsNote" },
				hex_color = hipatterns.gen_highlighter.hex_color(),
			},
		})
		local todo = [[\v<(TODO|FIXME|HACK|NOTE|WARN|PERF)>]]
		vim.keymap.set("n", "]t", function()
			vim.fn.search(todo)
		end, { desc = "Next todo comment" })
		vim.keymap.set("n", "[t", function()
			vim.fn.search(todo, "b")
		end, { desc = "Previous todo comment" })

		require("mini.icons").setup()
		MiniIcons.mock_nvim_web_devicons() -- for plugins that ask for nvim-web-devicons
	end,
}
