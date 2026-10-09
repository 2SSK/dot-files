#!/usr/bin/env bats
# theme: the central theme selector. Fake pkill, xrdb and tmux record what would be reloaded.

setup() {
	THEME="$BATS_TEST_DIRNAME/../.local/bin/theme"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	STATE="$XDG_STATE_HOME/desktop/theme"
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin"
	for tool in pkill xrdb tmux i3-msg kitten; do # fakes record their arguments instead of touching the real session
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
	# the whole config, so plugins (continuum hooks status-right) are re-applied after the theme
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
		gtk-4.0/settings.ini:gtk-settings.ini qt5ct/qt5ct.conf:qt5ct.conf qt6ct/qt6ct.conf:qt6ct.conf; do
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
