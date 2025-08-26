local themes = {
	"vague",
	"tokyonight",
	"nord",
	"onedark",
}

local colorscheme = themes[1]

return {
	require("config.plugins.themes." .. colorscheme),
}
