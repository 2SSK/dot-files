-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration
local config = wezterm.config_builder()

config.font = wezterm.font("JetBrains Mono Nerd Font", { weight = "Bold", italic = false })
config.font_size = 16

config.enable_tab_bar = false

config.window_decorations = "NONE"

-- tokyonight colorscheme:
config.colors = {
	foreground = "#a9b1d6",
	background = "#1a1b26",
	ansi = { "#32344a", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#ad8ee6", "#449dab", "#787c99" },
	brights = { "#444b6a", "#ff7a93", "#b9f27c", "#ff9e64", "#7da6ff", "#bb9af7", "#0db9d7", "#acb0d0" },
}

-- config.window_padding = { left = 50, right = 50, top = 50, bottom = 50 }

config.window_background_opacity = 0.9
config.macos_window_background_blur = 10

config.window_close_confirmation = "NeverPrompt"

return config
