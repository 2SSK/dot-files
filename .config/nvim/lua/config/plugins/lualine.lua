return {
	-- Gruvbox theme for lualine
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local lualine = require("lualine")
			local lazy_status = require("lazy.status") -- to configure lazy pending updates count

			local colors = {
				red = "#cc6666",
				orange = "#d7875f",
				yellow = "#d7af87",
				green = "#87af87",
				aqua = "#5fafaf",
				fg = "#d4be98",
				bg = "#1d2021",
				inactive_bg = "#3c3836",
				gray = "#928374",
			}

			local my_lualine_theme = {
				normal = {
					a = { bg = colors.aqua, fg = colors.bg, gui = "bold" },
					b = { bg = colors.bg, fg = colors.fg },
					c = { bg = colors.bg, fg = colors.fg },
				},
				insert = {
					a = { bg = colors.green, fg = colors.bg, gui = "bold" },
					b = { bg = colors.bg, fg = colors.fg },
					c = { bg = colors.bg, fg = colors.fg },
				},
				visual = {
					a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
					b = { bg = colors.bg, fg = colors.fg },
					c = { bg = colors.bg, fg = colors.fg },
				},
				command = {
					a = { bg = colors.orange, fg = colors.bg, gui = "bold" },
					b = { bg = colors.bg, fg = colors.fg },
					c = { bg = colors.bg, fg = colors.fg },
				},
				replace = {
					a = { bg = colors.red, fg = colors.bg, gui = "bold" },
					b = { bg = colors.bg, fg = colors.fg },
					c = { bg = colors.bg, fg = colors.fg },
				},
				inactive = {
					a = { bg = colors.inactive_bg, fg = colors.gray, gui = "bold" },
					b = { bg = colors.inactive_bg, fg = colors.gray },
					c = { bg = colors.inactive_bg, fg = colors.gray },
				},
			}

			-- configure lualine with modified theme
			lualine.setup({
				options = {
					theme = my_lualine_theme,
				},
				sections = {
					lualine_x = {
						{
							lazy_status.updates,
							cond = lazy_status.has_updates,
							color = { fg = colors.orange }, -- Changed to orange for consistency with gruvbox
						},
						{ "encoding" },
						{ "fileformat" },
						{ "filetype" },
					},
				},
			})
		end,
	},
	-- Tokyonight theme for lualine
	-- {
	--   "nvim-lualine/lualine.nvim",
	--   dependencies = { "nvim-tree/nvim-web-devicons" },
	--   config = function()
	--     local lualine = require("lualine")
	--     local lazy_status = require("lazy.status") -- to configure lazy pending updates count
	--
	--     local colors = {
	--       blue = "#65D1FF",
	--       green = "#3EFFDC",
	--       violet = "#FF61EF",
	--       yellow = "#FFDA7B",
	--       red = "#FF4A4A",
	--       fg = "#c3ccdc",
	--       bg = "#112638",
	--       inactive_bg = "#2c3043",
	--     }
	--
	--     local my_lualine_theme = {
	--       normal = {
	--         a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
	--         b = { bg = colors.bg, fg = colors.fg },
	--         c = { bg = colors.bg, fg = colors.fg },
	--       },
	--       insert = {
	--         a = { bg = colors.green, fg = colors.bg, gui = "bold" },
	--         b = { bg = colors.bg, fg = colors.fg },
	--         c = { bg = colors.bg, fg = colors.fg },
	--       },
	--       visual = {
	--         a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
	--         b = { bg = colors.bg, fg = colors.fg },
	--         c = { bg = colors.bg, fg = colors.fg },
	--       },
	--       command = {
	--         a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
	--         b = { bg = colors.bg, fg = colors.fg },
	--         c = { bg = colors.bg, fg = colors.fg },
	--       },
	--       replace = {
	--         a = { bg = colors.red, fg = colors.bg, gui = "bold" },
	--         b = { bg = colors.bg, fg = colors.fg },
	--         c = { bg = colors.bg, fg = colors.fg },
	--       },
	--       inactive = {
	--         a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
	--         b = { bg = colors.inactive_bg, fg = colors.semilightgray },
	--         c = { bg = colors.inactive_bg, fg = colors.semilightgray },
	--       },
	--     }
	--
	--     -- configure lualine with modified theme
	--     lualine.setup({
	--       options = {
	--         theme = my_lualine_theme,
	--       },
	--       sections = {
	--         lualine_x = {
	--           {
	--             lazy_status.updates,
	--             cond = lazy_status.has_updates,
	--             color = { fg = "#ff9e64" },
	--           },
	--           { "encoding" },
	--           { "fileformat" },
	--           { "filetype" },
	--         },
	--       },
	--     })
	--   end,
	-- },
}
