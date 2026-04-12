require("mini.indentscope").setup({
	draw = {
		delay = 0,
		animation = require("mini.indentscope").gen_animation.none(),
	},
})

require("mini.ai").setup()

require("mini.pairs").setup()

require("mini.surround").setup()

require("mini.diff").setup()

vim.keymap.set("n", "<leader>do", function()
	local diff = require("mini.diff")
	local buf = vim.api.nvim_get_current_buf()
	if not diff.get_buf_data(buf) then
		diff.enable(buf)
	end
	diff.toggle_overlay(buf)
end, { desc = "Toggle diff overlay" })

