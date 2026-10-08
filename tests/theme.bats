#!/usr/bin/env bats
# desktop-theme: the central theme selector. A fake pkill records reload signals.

setup() {
	THEME="$BATS_TEST_DIRNAME/../.local/bin/desktop-theme"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	STATE="$XDG_STATE_HOME/desktop/theme"
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	printf '#!/bin/sh\necho "$*" >>"%s"\n' "$BATS_TEST_TMPDIR/signals" >"$BATS_TEST_TMPDIR/bin/pkill"
	chmod +x "$BATS_TEST_TMPDIR/bin/pkill"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

signals() { cat "$BATS_TEST_TMPDIR/signals"; }

@test "set renders the central theme and reloads terminals" {
	run "$THEME" set catppuccin --mode light
	[ "$status" -eq 0 ]
	[ "$(cat "$STATE/current")" = "$(printf 'family=catppuccin\nmode=light')" ]
	[[ $(signals) == *"-USR1 -x kitty"* ]]
	[[ $(signals) == *"-USR2 -x foot"* ]]
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
