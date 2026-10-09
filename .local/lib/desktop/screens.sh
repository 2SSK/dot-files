# shellcheck shell=bash
# The login screen's and boot menu's backgrounds, made from the wallpaper: sddm shows it as it is,
# GRUB blurred and dimmed in the theme's background colour. Sourced by packages/system.sh (which
# installs them) and desktop-wallpaper (which redraws them when the wallpaper or theme changes).

login_background() { # <wallpaper> <out.jpg>
	magick "$1" -resize '2560x2560>' -strip -quality 90 "$2"
}

boot_background() { # <wallpaper> <colour> <out.jpg>
	magick "$1" -resize '1920x1080^' -gravity center -extent 1920x1080 -blur 0x24 \
		\( -size 1920x1080 "xc:$2" -alpha set -channel A -evaluate set 55% +channel \) -composite \
		-quality 92 "$3"
}
