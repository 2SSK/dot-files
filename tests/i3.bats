#!/usr/bin/env bats
# The i3 config passes i3's own check, with the theme's colours rendered where it includes them.

setup() {
	command -v i3 >/dev/null || skip 'i3 not installed'
	REPO="$BATS_TEST_DIRNAME/.."
	export HOME="$BATS_TEST_TMPDIR/home"
	XDG_STATE_HOME="$HOME/.local/state" python3 "$REPO/.local/lib/desktop/theme_render.py" render tokyonight dark
}

@test "i3 config has no errors" {
	run i3 -C -d all -c "$REPO/.config/i3/config"
	[ "$status" -eq 0 ]
	[[ $output == *"include ~/.local/state/desktop/theme/i3.conf"* ]]
	[[ $output != *"ERROR"* ]] || { grep ERROR <<<"$output" && false; }
}

@test "i3 starts nothing that Quickshell or the desktop-* commands replace" {
	run grep -nE 'polybar|nm-applet|i3status|pactl|brightnessctl|scrot|lockscreen|powermenu|xrandr --output' "$REPO/.config/i3/config"
	[ "$status" -eq 1 ]
}
