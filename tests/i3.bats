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

@test "i3 starts nothing that Quickshell or the desktop-* commands replace" {
	run grep -nE 'polybar|nm-applet|i3status|pactl|brightnessctl|scrot|lockscreen|powermenu|xrandr --output' \
		"$REPO/.config/i3/config" "$REPO"/.config/i3/conf.d/*.conf
	[ "$status" -eq 1 ]
}

@test "desktop-ctrl-release fails cleanly without an X display" {
	run env -u DISPLAY "$BATS_TEST_DIRNAME/../.local/bin/desktop-ctrl-release"
	[ "$status" -eq 1 ]
	[[ $output == *"no X display"* ]]
}
