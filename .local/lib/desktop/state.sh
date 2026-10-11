# shellcheck shell=bash
# Where the desktop keeps its choices (~/.local/state/desktop): the theme and the wallpaper, read the
# same way by every script. Sourced.

desktop_state="${XDG_STATE_HOME:-$HOME/.local/state}/desktop"
fallback_wallpaper="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../share/desktop/wallpapers/cat-mocha-lavender_19.jpg"

current_theme() { # prints "<family> <mode>"; tokyonight dark until a theme is set
	local family=tokyonight mode=dark
	# shellcheck disable=SC1091 # family= and mode=, written by theme_render.py
	[[ -r $desktop_state/theme/current ]] && source "$desktop_state/theme/current"
	echo "$family $mode"
}

current_wallpaper() { # the image set (its real path), else the repo's default
	local image
	image="$(readlink -f "$desktop_state/wallpaper" 2>/dev/null || true)"
	if [[ -f $image ]]; then echo "$image"; else echo "$fallback_wallpaper"; fi
}
