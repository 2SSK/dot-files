local themes = {
	"vague",
	"tokyonight",
	"catppuccin",
	"gruvbox",
	"nord",
	"onedark",
}

local colorscheme = themes[3]

return {
	require("config.plugins.themes." .. colorscheme),
}
