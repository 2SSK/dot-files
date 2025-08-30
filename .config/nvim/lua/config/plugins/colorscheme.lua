local themes = {
	"vague",
	"tokyonight",
	"catppuccin",
	"gruvbox",
	"nord",
	"onedark",
}

local colorscheme = themes[5]

return {
	require("config.plugins.themes." .. colorscheme),
}
