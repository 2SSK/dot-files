-- Follow the desktop theme: `theme` renders ~/.local/state/desktop/theme/nvim.lua and sends
-- SIGUSR1; every running nvim reloads colors/desktop.lua.
local M = {}

local state = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/desktop/theme/nvim.lua"

function M.read()
	local ok, theme = pcall(dofile, state)
	return ok and type(theme) == "table" and theme or nil
end

function M.apply()
	if not pcall(vim.cmd.colorscheme, "desktop") then
		vim.cmd.colorscheme("default")
	end
end

function M.setup()
	-- Transparent background, so the terminal's opacity shows through
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("desktop-theme", { clear = true }),
		callback = function()
			for _, group in ipairs({
				"Normal", "NormalNC", "NormalFloat", "FloatBorder", "SignColumn", "FoldColumn", "EndOfBuffer",
				"LineNr", "LineNrAbove", "LineNrBelow", "CursorLineNr", "TabLine", "TabLineFill",
				"StatusLine", "StatusLineNC",
				"Pmenu", "PmenuExtra", "PmenuKind", "PmenuSbar", -- completion menu (blink.cmp links here)
			}) do
				local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
				hl.bg = nil
				vim.api.nvim_set_hl(0, group, hl)
			end
		end,
	})
	vim.api.nvim_create_autocmd("Signal", {
		group = "desktop-theme",
		pattern = "SIGUSR1",
		nested = true, -- so :colorscheme fires ColorScheme (transparency above, lualine)
		callback = function()
			M.apply()
			vim.cmd.redraw({ bang = true })
		end,
	})
	M.apply()
end

return M
