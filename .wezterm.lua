-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration
local config = wezterm.config_builder()

config.font = wezterm.font("JetBrains Mono Nerd Font", { weight = "Bold", italic = false })
config.font_size = 14

config.enable_tab_bar = false

config.window_decorations = "NONE"

-- my coolnight colorscheme:
config.colors = {
	foreground = "#CBE0F0",
	background = "#011423",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
	brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}

-- config.window_padding = { left = 50, right = 50, top = 50, bottom = 50 }

config.window_background_opacity = 0.9
config.macos_window_background_blur = 10

config.window_close_confirmation = "NeverPrompt"

return config
