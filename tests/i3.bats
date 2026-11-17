#!/usr/bin/env bats
# The i3 config and its modules pass i3's own check, with the theme rendered where they include it.

setup() {
	command -v i3 >/dev/null || skip 'i3 not installed'
	REPO="$BATS_TEST_DIRNAME/.."
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME/.config"
	ln -s "$REPO/.config/i3" "$HOME/.config/i3" # the modules are included from ~/.config/i3
	XDG_STATE_HOME="$HOME/.local/state" python3 "$REPO/.local/lib/desktop/theme_render.py" render tokyonight dark
}

@test "i3 config and every module load without errors" {
	run i3 -C -d all -c "$REPO/.config/i3/config"
	[ "$status" -eq 0 ]
	local module
	for module in "$REPO"/.config/i3/conf.d/*.conf; do
		[[ $output == *"cfg_include"*"conf.d/${module##*/}"* ]] || { echo "not included: ${module##*/}" && false; }
	done
	[[ $output == *"cfg_include"*"theme/i3.conf"* ]]
	[[ $output != *"ERROR"* ]] || { grep ERROR <<<"$output" && false; }
}

@test "i3 runs the minimal session: polybar, dunst, the clipboard history; no Quickshell" {
	run grep -nE 'qs -c|quickshell|nm-applet|i3status|pactl|scrot|lockscreen|xrandr --output' \
		"$REPO/.config/i3/config" "$REPO"/.config/i3/conf.d/*.conf
	[ "$status" -eq 1 ]
	grep -qx 'exec --no-startup-id desktop bar start' "$REPO/.config/i3/conf.d/autostart.conf"
	grep -q '|| dunst$' "$REPO/.config/i3/conf.d/autostart.conf"
	grep -qx 'exec --no-startup-id desktop cliphist keep' "$REPO/.config/i3/conf.d/autostart.conf"
	grep -qx 'set $shell exec --no-startup-id desktop i3' "$REPO/.config/i3/config"
}

@test "sway keeps the Quickshell shell for the keys i3 shares with it" {
	grep -qx 'set $shell exec --no-startup-id qs -c desktop ipc call' "$REPO/.config/sway/desktop.conf"
	grep -qx 'include ~/.config/i3/conf.d/keys.conf' "$REPO/.config/sway/desktop.conf"
}

@test "desktop key-release fails cleanly without an X display, and on an unknown key" {
	run env -u DISPLAY "$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/key-release" alt
	[ "$status" -eq 1 ]
	[[ $output == *"no X display"* ]]
	run "$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/key-release" hyper
	[ "$status" -eq 2 ]
}
