-- Mode pill in the theme's colour, branch on the surface colour, a transparent middle; rebuilt
-- whenever the desktop theme changes
local function theme()
	local t = require("config.theme").read()
	if not t or not t.ui then
		return "auto"
	end
	local ui = t.ui
	local function mode(colour)
		return {
			a = { fg = ui.on_primary, bg = colour, gui = "bold" },
			b = { fg = colour, bg = ui.surface },
			c = { fg = ui.fg, bg = "NONE" },
		}
	end
	local dim = { fg = ui.fg_muted, bg = "NONE" }
	return {
		normal = mode(ui.primary),
		insert = mode(ui.success),
		visual = mode(ui.accent),
		replace = mode(ui.error),
		command = mode(ui.warning),
		terminal = mode(ui.success),
		inactive = { a = dim, b = dim, c = dim },
	}
end

return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	config = function()
		local function setup()
			require("lualine").setup({
				options = { theme = theme(), section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" } },
			})
		end
		setup()
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("lualine-desktop", { clear = true }),
			callback = setup,
		})
	end,
}
