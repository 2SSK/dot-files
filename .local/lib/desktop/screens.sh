# shellcheck shell=bash
# The login screen's background, made from the wallpaper, and the boot menu's theme, made from the
# palette. Sourced by packages/system.sh (which installs them), desktop-wallpaper and theme (which
# redraw them when the wallpaper or the theme changes).

login_background() { # <wallpaper> <out.jpg>
	magick "$1" -resize '2560x2560>' -strip -quality 90 "$2"
}

# <rendered grub-theme.txt> <theme dir>: the boot menu's theme.txt, and its background, a soft
# gradient from the theme's background (lightened toward its surface at the centre, darkened at the
# edges) with a little grain against banding. Written in place, and only when different: in /boot
# only these two files are ours (system.sh grub), not the folder. The grain's seed is fixed, so the
# same theme draws the same picture.
boot_theme() {
	local src=$1 dir=$2 bg surface centre edge tmp
	read -r bg surface < <(sed -n 's/^# background: //p' "$src")
	centre="$(magick xc:"$surface" xc:"$bg" -compose blend -define compose:args=63 -composite -depth 8 -format '#%[hex:p{0,0}]' info:)"
	edge="$(magick xc:"$bg" -fill black -colorize 25% -depth 8 -format '#%[hex:p{0,0}]' info:)"
	tmp="$(mktemp --suffix=.png)"
	magick -size 1920x1080 radial-gradient:"$centre"-"$edge" -seed 1 -attenuate 0.25 +noise Uniform -depth 8 -strip -define png:exclude-chunks=date,time "PNG24:$tmp"
	cmp -s "$src" "$dir/theme.txt" || cat "$src" >"$dir/theme.txt"
	cmp -s "$tmp" "$dir/background.png" || cat "$tmp" >"$dir/background.png"
	rm -f "$tmp"
}
