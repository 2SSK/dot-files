return {
	"rmagatti/auto-session",
	config = function()
		require("auto-session").setup({
			auto_restore_enabled = false,
			auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
		})
		vim.keymap.set("n", "<leader>Sr", "<cmd>AutoSession restore<CR>", { desc = "Restore session" })
		vim.keymap.set("n", "<leader>Ss", "<cmd>AutoSession save<CR>", { desc = "Save session" })
	end,
}
