-- A floating terminal that keeps its shell between toggles (Space t t, or :Floaterminal)
local state = { buf = -1, win = -1 }

local function toggle()
	if vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_hide(state.win)
		return
	end
	if not vim.api.nvim_buf_is_valid(state.buf) then
		state.buf = vim.api.nvim_create_buf(false, true)
	end
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	})
	if vim.bo[state.buf].buftype ~= "terminal" then
		vim.cmd.terminal()
	end
end

vim.api.nvim_create_user_command("Floaterminal", toggle, {})
vim.keymap.set({ "n", "t" }, "<leader>tt", toggle, { desc = "Floating terminal" })
