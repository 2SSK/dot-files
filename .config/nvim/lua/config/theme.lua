-- Follow the desktop theme: colors/desktop.lua builds a base16 scheme from the theme's palette
-- (~/.local/state/desktop/theme/palette.json); `theme` sends SIGUSR1 and every nvim reloads it.
local M = {}

local state = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/desktop/theme/palette.json"

-- { background, palette (base00..base0F), ui (the theme's roles) }, or nil without a theme
function M.read()
	local ok, p = pcall(function()
		return vim.json.decode(table.concat(vim.fn.readfile(state), "\n"))
	end)
	if not ok or type(p) ~= "table" or type(p.ui) ~= "table" then
		return nil
	end
	local u, a = p.ui, p.ansi or {}
	return {
		background = p.mode,
		palette = {
			base00 = u.bg, base01 = u.surface, base02 = u.selection, base03 = u.fg_muted,
			base04 = u.fg_muted, base05 = u.fg, base06 = u.fg, base07 = u.fg,
			base08 = u.error, base09 = u.accent, base0A = u.warning, base0B = u.success,
			base0C = a.c6, base0D = u.primary, base0E = u.secondary, base0F = a.c9,
		},
		ui = u,
	}
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
