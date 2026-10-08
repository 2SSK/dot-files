-- Follow the desktop theme: `theme` writes ~/.local/state/desktop/theme/nvim.lua
-- ({ colorscheme, background }) and sends SIGUSR1; every running nvim re-applies it.
local M = {}

local state = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/desktop/theme/nvim.lua"
local fallback = { colorscheme = "tokyonight-night", background = "dark" }

function M.apply()
	local ok, theme = pcall(dofile, state)
	if not ok or type(theme) ~= "table" then
		theme = fallback
	end
	vim.o.background = theme.background
	if not pcall(vim.cmd.colorscheme, theme.colorscheme) then
		vim.cmd.colorscheme(fallback.colorscheme)
	end
end

function M.setup()
	-- Transparent background for every colourscheme, so the terminal's opacity shows through
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("desktop-theme", { clear = true }),
		callback = function()
			for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "FloatBorder", "SignColumn", "EndOfBuffer" }) do
				local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
				hl.bg = nil
				vim.api.nvim_set_hl(0, group, hl)
			end
		end,
	})
	vim.api.nvim_create_autocmd("Signal", {
		group = "desktop-theme",
		pattern = "SIGUSR1",
		-- nested: :colorscheme must fire its autocmds here, or lazy.nvim cannot load the
		-- scheme's plugin and the ColorScheme hook above does not run
		nested = true,
		callback = function()
			M.apply()
			vim.cmd.redraw({ bang = true })
		end,
	})
	M.apply()
end

return M
