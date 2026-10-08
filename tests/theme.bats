#!/usr/bin/env bats
# theme: the central theme selector. Fake pkill, xrdb and tmux record what would be reloaded.

setup() {
	THEME="$BATS_TEST_DIRNAME/../.local/bin/theme"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	STATE="$XDG_STATE_HOME/desktop/theme"
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin"
	for tool in pkill xrdb tmux; do # fakes record their arguments instead of touching the real session
		printf '#!/bin/sh\necho "%s $*" >>"%s"\n' "$tool" "$BATS_TEST_TMPDIR/signals" >"$BATS_TEST_TMPDIR/bin/$tool"
		chmod +x "$BATS_TEST_TMPDIR/bin/$tool"
	done
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
	unset DISPLAY
}

signals() { cat "$BATS_TEST_TMPDIR/signals"; }

@test "set renders the central theme and reloads terminals" {
	run "$THEME" set catppuccin --mode light
	[ "$status" -eq 0 ]
	[ "$(cat "$STATE/current")" = "$(printf 'family=catppuccin\nmode=light')" ]
	[[ $(signals) == *"pkill -USR1 -x kitty"* ]]
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
