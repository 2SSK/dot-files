#!/usr/bin/env bats
# theme: the central theme selector. Fake pkill, xrdb and tmux record what would be reloaded.

setup() {
	# never the real login screen (system.sh shares their backgrounds and colours with us)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/no-sddm" DESKTOP_GRUB_DIR="$BATS_TEST_TMPDIR/no-grub"
	THEME="$BATS_TEST_DIRNAME/../.local/bin/theme"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	STATE="$XDG_STATE_HOME/desktop/theme"
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin"
	# herdr is "running" (pgrep answers for it alone, so nautilus stays not running) and a fake herdr
	# records the reload, never the real herdr's
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\n[ "$*" = "-x herdr" ]\n' >"$BATS_TEST_TMPDIR/bin/pgrep"
	chmod +x "$BATS_TEST_TMPDIR/bin/pgrep"
	for tool in pkill xrdb tmux i3-msg kitten herdr; do # fakes record their arguments instead of touching the real session
		printf '#!/bin/sh\necho "%s $*" >>"%s"\n' "$tool" "$BATS_TEST_TMPDIR/signals" >"$BATS_TEST_TMPDIR/bin/$tool"
		chmod +x "$BATS_TEST_TMPDIR/bin/$tool"
	done
	# gsettings knows the GNOME interface schema and records what theme sets; never the real dconf
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\n[ "$1" = list-schemas ] && echo org.gnome.desktop.interface && exit\necho "gsettings $*" >>"%s"\n' \
		"$BATS_TEST_TMPDIR/signals" >"$BATS_TEST_TMPDIR/bin/gsettings"
	chmod +x "$BATS_TEST_TMPDIR/bin/gsettings"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
	unset DISPLAY XDG_CONFIG_HOME
	export XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
	mkdir -p "$XDG_RUNTIME_DIR"
}

kitty_socket() { # a listening kitty's socket, as kitty.conf's listen_on names it
	python3 -c 'import socket, sys; socket.socket(socket.AF_UNIX).bind(sys.argv[1])' "$XDG_RUNTIME_DIR/kitty-$1"
}

signals() { cat "$BATS_TEST_TMPDIR/signals"; }

@test "set renders the central theme and reloads terminals" {
	run "$THEME" set catppuccin --mode light
	[ "$status" -eq 0 ]
	[ "$(cat "$STATE/current")" = "$(printf 'family=catppuccin\nmode=light')" ]
	[[ $(signals) != *"pkill -USR1 -x kitty"* ]] # a full config reload blinks; colours go over the socket
	[[ $(signals) == *"pkill -USR2 -x foot"* ]]
	[[ $(signals) == *"pkill -USR2 -x cava"* ]]
	[[ $(signals) == *"pkill -USR1 -x nvim"* ]]
	# the whole config, so plugins are re-applied after the theme
	[[ $(signals) == *"tmux source-file ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"* ]]
	[[ $(signals) != *"xrdb"* ]] # no X display: st is left alone
}

@test "with an X display, st gets the new colours through xrdb" {
	echo '! test' >"$HOME/.Xresources"
	DISPLAY=:99 run "$THEME" set gruvbox
	[ "$status" -eq 0 ]
	[[ $(signals) == *"xrdb -merge $HOME/.Xresources"* ]]
	[[ $(signals) == *"pkill -USR1 -x st"* ]]
	grep -qx 'st.background: #282828' "$STATE/st.Xresources"
}

@test "set keeps the current mode when --mode is omitted" {
	"$THEME" set gruvbox --mode light
	run "$THEME" set rosepine
	[ "$status" -eq 0 ]
	grep -qx 'mode=light' "$STATE/current"
}

@test "mode switches and toggles within the current family" {
	"$THEME" set tokyonight
	"$THEME" mode light
	grep -qx 'mode=light' "$STATE/current"
	"$THEME" mode toggle
	grep -qx 'mode=dark' "$STATE/current"
	grep -qx 'family=tokyonight' "$STATE/current"
}

@test "current prints family and mode" {
	"$THEME" set gruvbox --mode dark
	run "$THEME" current
	[ "$output" = "gruvbox dark" ]
}

@test "current defaults to tokyonight dark before any theme is set" {
	run "$THEME" current
	[ "$output" = "tokyonight dark" ]
}

@test "list shows every family and marks the current one" {
	"$THEME" set catppuccin
	run "$THEME" list
	[ "$status" -eq 0 ]
	[[ $output == *"* catppuccin"* ]]
	[[ $output == *"  gruvbox"* && $output == *"  rosepine"* && $output == *"  eink"* && $output == *"  tokyonight"* ]]
}

@test "list --json gives each family's name and its dark and light colours" {
	run "$THEME" list --json
	[ "$status" -eq 0 ]
	python3 -c '
import json, sys
themes = json.loads(sys.argv[1])
cat = next(t for t in themes if t["family"] == "catppuccin")
assert cat["name"] == "Catppuccin", cat
assert cat["dark"]["bg"] == "#1e1e2e" and cat["dark"]["primary"] == "#89b4fa", cat
assert cat["light"]["bg"].startswith("#"), cat
assert {t["family"] for t in themes} >= {"gruvbox", "tokyonight", "eink"}
' "$output"
}

@test "yazi gets the desktop flavor: a valid theme in the theme's colours, its own theme.toml kept aside" {
	export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
	mkdir -p "$XDG_CONFIG_HOME/yazi"
	printf '[flavor]\ndark = "noctalia"\n' >"$XDG_CONFIG_HOME/yazi/theme.toml"
	run "$THEME" set catppuccin
	[ "$status" -eq 0 ]
	flavor="$XDG_CONFIG_HOME/yazi/flavors/desktop.yazi"
	[ "$(readlink "$flavor/flavor.toml")" = "$STATE/yazi-flavor.toml" ]
	[ "$(readlink "$flavor/tmtheme.xml")" = "$STATE/silicon.tmTheme" ]
	[ "$(readlink "$XDG_CONFIG_HOME/yazi/theme.toml")" = "$STATE/yazi-theme.toml" ]
	python3 -c 'import sys, tomllib; t = tomllib.load(open(sys.argv[1], "rb")); assert t["mgr"]["cwd"]["fg"] == "#89b4fa", t["mgr"]; assert "icon" not in t' "$flavor/flavor.toml"
	python3 -c 'import sys, tomllib; assert tomllib.load(open(sys.argv[1], "rb"))["flavor"]["dark"] == "desktop"' "$XDG_CONFIG_HOME/yazi/theme.toml"
	ls "$XDG_STATE_HOME"/desktop/backup/theme/yazi/theme.toml.* # noctalia's, moved aside
}

@test "herdr gets a config in the theme's colours with tmux's keys; a running herdr reloads it" {
	export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
	mkdir -p "$XDG_CONFIG_HOME/herdr"
	printf '[keys]\nprefix = "ctrl+b"\n' >"$XDG_CONFIG_HOME/herdr/config.toml"
	run "$THEME" set catppuccin --mode dark
	[ "$status" -eq 0 ]
	[ "$(readlink "$XDG_CONFIG_HOME/herdr/config.toml")" = "$STATE/herdr.toml" ]
	python3 -c '
import sys, tomllib
c = tomllib.load(open(sys.argv[1], "rb"))
assert c["theme"]["custom"]["accent"] == "#89b4fa" and c["theme"]["custom"]["text"] == "#cdd6f4", c["theme"]
k = c["keys"]
assert k["prefix"] == "backtick" and k["split_vertical"] == "prefix+w" and k["split_horizontal"] == "prefix+s", k
assert "ctrl+h" not in str(k).replace("prefix+ctrl+h", ""), "Ctrl+h without the prefix belongs to nvim"
' "$XDG_CONFIG_HOME/herdr/config.toml"
	[[ $(signals) == *"herdr server reload-config"* ]]
	ls "$XDG_STATE_HOME"/desktop/backup/theme/herdr/config.toml.* # the old one, moved aside
	if [[ -x /usr/bin/herdr ]]; then # herdr's own check: every key valid, none bound twice
		run env HERDR_CONFIG_PATH="$XDG_CONFIG_HOME/herdr/config.toml" /usr/bin/herdr config check
		[ "$output" = "config: ok" ]
	fi
}


@test "unknown family fails and leaves the theme unchanged" {
	"$THEME" set gruvbox
	run "$THEME" set nope
	[ "$status" -eq 1 ]
	grep -qx 'family=gruvbox' "$STATE/current"
}

@test "bad usage exits 2" {
	run "$THEME" mode dim
	[ "$status" -eq 2 ]
	run "$THEME" bogus
	[ "$status" -eq 2 ]
	run "$THEME" set
	[ "$status" -eq 2 ]
}

@test "--help exits 0" {
	run "$THEME" --help
	[ "$status" -eq 0 ]
	[[ $output == *"usage:"* ]]
}

@test "GTK and Qt: their fixed config paths link to the rendered files" {
	run "$THEME" set tokyonight --mode dark
	[ "$status" -eq 0 ]
	local link
	for link in gtk-3.0/gtk.css:gtk-3.0.css gtk-4.0/gtk.css:gtk-4.0.css gtk-3.0/settings.ini:gtk-settings.ini \
		gtk-4.0/settings.ini:gtk-settings.ini qt5ct/qt5ct.conf:qtct.conf qt6ct/qt6ct.conf:qtct.conf; do
		[ "$(readlink "$HOME/.config/${link%%:*}")" = "$STATE/${link#*:}" ]
	done
	grep -q '@define-color accent_bg_color #7aa2f7;' "$HOME/.config/gtk-3.0/gtk.css"
	grep -q -- '--window-bg-color: #1a1b26;' "$HOME/.config/gtk-4.0/gtk.css"
	grep -qx "color_scheme_path=$STATE/qt-colors.conf" "$HOME/.config/qt6ct/qt6ct.conf"
	grep -qx 'icon_theme=Tela-circle-blue-dark' "$HOME/.config/qt5ct/qt5ct.conf"
	grep -qx 'gtk-theme-name=adw-gtk3-dark' "$HOME/.config/gtk-4.0/settings.ini"
}

@test "an existing GTK or Qt config is moved aside, not deleted" {
	mkdir -p "$HOME/.config/gtk-3.0"
	echo '/* mine */' >"$HOME/.config/gtk-3.0/gtk.css"
	run "$THEME" set tokyonight
	[ "$status" -eq 0 ]
	[[ $output == *"event=moved_aside"* ]]
	[ -L "$HOME/.config/gtk-3.0/gtk.css" ]
	grep -rq 'mine' "$XDG_STATE_HOME/desktop/backup/theme/gtk-3.0/"
}

@test "mode sets GTK's dark/light, theme and icons through gsettings" {
	run "$THEME" set gruvbox --mode light
	[[ $(signals) == *"gsettings set org.gnome.desktop.interface color-scheme prefer-light"* ]]
	[[ $(signals) == *"gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3"* ]]
	[[ $(signals) == *"gsettings set org.gnome.desktop.interface icon-theme Tela-circle-blue-light"* ]]
	run "$THEME" mode dark
	[[ $(signals) == *"color-scheme prefer-dark"* && $(signals) == *"gtk-theme adw-gtk3-dark"* ]]
	[[ $(signals) == *"pkill -HUP -x xsettingsd"* ]]
}

@test "every app in the consumers table uses a file the renderer produces" {
	"$THEME" set tokyonight
	local file
	while read -r file _; do
		[ -f "$STATE/$file" ] || { echo "no rendered $file" && false; }
	done < <(sed -n "/^consumers() {/,/^}/{/^[a-z0-9]/p}" "$THEME" | grep -v '^consumers')
}

@test "a switch swaps the whole theme at once" {
	"$THEME" set tokyonight
	[ -L "$STATE" ]
	local first
	first="$(readlink -f "$STATE")"
	"$THEME" set gruvbox
	[ "$(readlink -f "$STATE")" != "$first" ]
	[ ! -e "$first" ] # the previous render is gone
}

@test "kitty windows are recoloured over their sockets, nothing else reloads them" {
	kitty_socket 101
	kitty_socket 202
	run "$THEME" set rosepine --mode dark
	[ "$status" -eq 0 ]
	[[ $(signals) == *"kitten @ --to unix:$XDG_RUNTIME_DIR/kitty-101 set-colors --all --configured $STATE/kitty.conf"* ]]
	[[ $(signals) == *"kitten @ --to unix:$XDG_RUNTIME_DIR/kitty-202 set-colors"* ]]
	[[ $(signals) != *"picom"* ]] # its reset would redraw the whole screen
}

@test "a switch prints nothing unless something goes wrong" {
	run "$THEME" set gruvbox
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "set updates the login screen's colours where system.sh sddm shared them, and nowhere else" {
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/sddm"
	run "$THEME" set kanagawa
	[ "$status" -eq 0 ]
	[ ! -e "$DESKTOP_SDDM_DIR" ]
	mkdir "$DESKTOP_SDDM_DIR"
	run "$THEME" set kanagawa
	grep -qx 'bg=#1f1f28' "$DESKTOP_SDDM_DIR/theme.conf"
	run "$THEME" set nord
	! grep -qx 'bg=#1f1f28' "$DESKTOP_SDDM_DIR/theme.conf"
}

@test "vim builds its colours from the palette, backgrounds transparent" {
	command -v vim >/dev/null || skip 'vim not installed'
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	python3 "$BATS_TEST_DIRNAME/../.local/lib/desktop/theme_render.py" render tokyonight dark >/dev/null
	run vim -Nu NONE -es --cmd "set rtp^=$BATS_TEST_DIRNAME/../.vim" -c 'set termguicolors' -c 'colorscheme desktop' \
		-c 'redir! > /dev/stdout' -c 'hi Normal' -c 'hi Function' -c 'redir END' -c 'qa!'
	[[ $output == *"Normal"*"guifg=#c0caf5"* && $output != *"Normal"*"guibg=#"* ]]
	[[ $output == *"Function"*"guifg=#7aa2f7"* ]]
}

boot_menu() { # the folder system.sh grub shares: its theme.txt and background are ours
	export DESKTOP_GRUB_DIR="$BATS_TEST_TMPDIR/grub"
	mkdir -p "$DESKTOP_GRUB_DIR"
	echo old >"$DESKTOP_GRUB_DIR/theme.txt"
	echo old >"$DESKTOP_GRUB_DIR/background.png"
}

@test "set redraws the boot menu where system.sh grub shared it, in the family's dark colours" {
	boot_menu
	run "$THEME" set catppuccin --mode light
	[ "$status" -eq 0 ]
	# drawn in the background (the switch doesn't wait for a picture only the next boot shows)
	for _ in $(seq 100); do
		[ "$(magick identify -format '%m %wx%h' "$DESKTOP_GRUB_DIR/background.png" 2>/dev/null)" = "PNG 1920x1080" ] && break
		sleep 0.1
	done
	grep -q 'selected_item_color = "#cdd6f4"' "$DESKTOP_GRUB_DIR/theme.txt" # mocha's text, not latte's
	grep -q 'item_color = "#a6adc8"' "$DESKTOP_GRUB_DIR/theme.txt"
	! grep -q '#4c4f69' "$DESKTOP_GRUB_DIR/theme.txt"
	[ "$(magick identify -format '%m %wx%h' "$DESKTOP_GRUB_DIR/background.png")" = "PNG 1920x1080" ]
	# a gradient from the background lightened toward the surface (centre) to it darkened (edges)
	centre="$(magick "$DESKTOP_GRUB_DIR/background.png" -crop 64x64+928+508 -resize 1x1 -depth 8 -format '%[hex:p{0,0}]' info:)"
	corner="$(magick "$DESKTOP_GRUB_DIR/background.png" -crop 64x64+0+0 -resize 1x1 -depth 8 -format '%[hex:p{0,0}]' info:)"
	[[ $((16#${centre:0:2})) -gt $((16#${corner:0:2})) ]]
	[ -z "$(find "$DESKTOP_GRUB_DIR" -name '.*')" ] # nothing left behind
}

@test "a boot menu that isn't ours, or isn't there, is left alone" {
	run "$THEME" set nord
	[ "$status" -eq 0 ]
	[ ! -e "$BATS_TEST_TMPDIR/no-grub" ]
	boot_menu
	chmod a-w "$DESKTOP_GRUB_DIR/theme.txt" "$DESKTOP_GRUB_DIR/background.png"
	run "$THEME" set kanagawa
	[ "$status" -eq 0 ]
	[ "$(cat "$DESKTOP_GRUB_DIR/theme.txt")" = old ]
	[ "$(cat "$DESKTOP_GRUB_DIR/background.png")" = old ]
}

fonts_collection() { # <name>: the desktop's chosen font collection, as the shell saves it
	export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
	mkdir -p "$XDG_CONFIG_HOME/desktop"
	printf '{"bar": {"style": "island"}, "fonts": {"collection": "%s", "scale": 1.15}}\n' "$1" >"$XDG_CONFIG_HOME/desktop/shell.json"
}

@test "fonts: the chosen collection reaches every app's rendered config" {
	fonts_collection geist
	run "$THEME" set catppuccin --mode dark
	[ "$status" -eq 0 ]
	grep -qx 'gtk-font-name=Geist 11' "$STATE/gtk-settings.ini"
	grep -qx 'Gtk/FontName "Geist 11"' "$STATE/xsettingsd.conf"
	grep -qx 'Gtk/MonospaceFontName "GeistMono Nerd Font 11"' "$STATE/xsettingsd.conf"
	grep -qx 'general="Geist,11"' "$STATE/qtct.conf"
	grep -qx 'fixed="GeistMono Nerd Font,11"' "$STATE/qtct.conf"
	grep -qx 'font_family GeistMono Nerd Font' "$STATE/kitty.conf"
	grep -qx 'font=GeistMono Nerd Font:size=14' "$STATE/foot.ini"
	grep -q '^st.font: GeistMono Nerd Font:size=14' "$STATE/st.Xresources"
	grep -qx 'font pango:Geist, GeistMono Nerd Font, JetBrainsMono Nerd Font Medium 13' "$STATE/i3.conf"
	grep -qx 'font=Geist' "$STATE/sddm-theme.conf"
	python3 -c '
import json, sys
s = sys.argv[1]
c = json.load(open(s + "/vscodium/colors.json"))
assert c["editor.fontFamily"].startswith("GeistMono Nerd Font") and c["terminal.integrated.fontFamily"] == "GeistMono Nerd Font", c
p = json.load(open(s + "/palette.json"))["fonts"]
assert {k: p[k] for k in ("collection", "ui", "display", "mono")} == {"collection": "geist", "ui": "Geist", "display": "Geist", "mono": "GeistMono Nerd Font"}, p
assert p["all"]["sf"]["display"] == "SF Compact Display" and set(p["all"]) == {"inter", "geist", "sf"}, p["all"]
' "$STATE"
	# fontconfig: what browsers and anything asking for sans-serif or monospace get, linked into place
	[ "$(readlink "$XDG_CONFIG_HOME/fontconfig/fonts.conf")" = "$STATE/fontconfig.conf" ]
	grep -q '<family>sans-serif</family>' "$STATE/fontconfig.conf"
	python3 -c '
import sys, xml.etree.ElementTree as E
alias = {a.find("family").text: [f.text for f in a.find("prefer")] for a in E.parse(sys.argv[1]).getroot().iter("alias")}
assert alias["sans-serif"][0] == "Geist" and alias["monospace"][0] == "GeistMono Nerd Font", alias
assert "JetBrainsMono Nerd Font" in alias["monospace"], "icons fall back to the Nerd Font"
' "$STATE/fontconfig.conf"
	# GTK on Wayland and libadwaita read gsettings
	[[ $(signals) == *"gsettings set org.gnome.desktop.interface font-name Geist 11"* ]]
	[[ $(signals) == *"gsettings set org.gnome.desktop.interface monospace-font-name GeistMono Nerd Font 11"* ]]
}

@test "fonts: Inter and JetBrains Mono when none is chosen" {
	export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
	run "$THEME" set catppuccin
	[ "$status" -eq 0 ]
	grep -qx 'gtk-font-name=Inter 11' "$STATE/gtk-settings.ini"
	grep -qx 'font_family JetBrainsMono Nerd Font' "$STATE/kitty.conf"
	python3 -c 'import json, sys; assert json.load(open(sys.argv[1]))["fonts"]["display"] == "Inter Display"' "$STATE/palette.json"
}

@test "fonts: another collection renders again, even with the same theme" {
	fonts_collection inter
	"$THEME" set catppuccin --mode dark
	grep -qx 'font_family JetBrainsMono Nerd Font' "$STATE/kitty.conf"
	fonts_collection sf
	"$THEME" set catppuccin --mode dark
	grep -qx 'font_family SF Mono' "$STATE/kitty.conf"
	grep -qx 'gtk-font-name=SF Pro Text 11' "$STATE/gtk-settings.ini"
}
