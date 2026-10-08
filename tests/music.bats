#!/usr/bin/env bats
# music with fake mpc and rmpc that record what would happen.

setup() {
	MUSIC="$BATS_TEST_DIRNAME/../.local/bin/music"
	export HOME="$BATS_TEST_TMPDIR/home" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$HOME/Music/90s" "$BATS_TEST_TMPDIR/bin"
	for tool in mpc rmpc; do
		# shellcheck disable=SC2016 # $* and $CALLS expand when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$BATS_TEST_TMPDIR/bin/$tool"
		chmod +x "$BATS_TEST_TMPDIR/bin/$tool"
	done
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "plays a folder shuffled, then opens the player" {
	run "$MUSIC" 90s
	[ "$status" -eq 0 ]
	[ "$(cat "$CALLS")" = "$(printf '%s\n' 'mpc -q update --wait 90s' 'mpc -q clear' 'mpc -q add 90s' \
		'mpc -q random on' 'mpc -q play' 'rmpc ')" ]
}

@test "a missing folder fails without touching mpd" {
	run "$MUSIC" nope
	[ "$status" -eq 1 ]
	[[ $output == *"event=no_folder"* ]]
	[ ! -e "$CALLS" ]
}

@test "--help exits 0" {
	run "$MUSIC" --help
	[ "$status" -eq 0 ]
}
