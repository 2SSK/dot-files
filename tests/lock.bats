#!/usr/bin/env bats
# desktop-lock: the locker in the desktop theme, with fake i3lock/swaylock recording their arguments.

setup() {
	LOCK="$BATS_TEST_DIRNAME/../.local/bin/desktop-lock"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" ARGS="$BATS_TEST_TMPDIR/args"
	mkdir -p "$XDG_STATE_HOME/desktop/theme" "$BATS_TEST_TMPDIR/bin"
	printf '{"ui": {"bg": "#1f1f28", "fg": "#dcd7ba", "primary": "#7e9cd8", "error": "#e82424"}}\n' >"$XDG_STATE_HOME/desktop/theme/palette.json"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
	unset WAYLAND_DISPLAY
}

fake() { # <name> <version line>
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\n[ "$1" = --version ] && echo "%s" && exit 0\necho "$@" >"$ARGS"\n' "$2" >"$BATS_TEST_TMPDIR/bin/$1"
	chmod +x "$BATS_TEST_TMPDIR/bin/$1"
}

@test "i3lock-color: the wallpaper blurred and cached, a clock and a small ring, in the theme" {
	fake i3lock 'i3lock: version 2.13.c.5'
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\nfor last; do :; done\necho png >"$last"\necho run >>"$ARGS.magick"\n' >"$BATS_TEST_TMPDIR/bin/magick"
	chmod +x "$BATS_TEST_TMPDIR/bin/magick"
	export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
	run "$LOCK"
	[ "$status" -eq 0 ]
	[[ $(cat "$ARGS") == *"--nofork"* ]]
	[[ $(cat "$ARGS") =~ --image\ $XDG_CACHE_HOME/desktop/lock-1f1f28-[0-9a-f]{12}\.png\ --fill ]]
	[[ $(cat "$ARGS") == *"--radius 20"* ]]
	[[ $(cat "$ARGS") != *"--bar-indicator"* ]]
	[[ $(cat "$ARGS") == *"--keyhl-color 7e9cd8ff"* ]]
	[[ $(cat "$ARGS") == *"--ringwrong-color e82424ff"* ]]
	run "$LOCK" # cached: the picture isn't made again
	[ "$(wc -l <"$ARGS.magick")" -eq 1 ]
}

@test "i3lock-color blurs the screen when the wallpaper can't be prepared" {
	fake i3lock 'i3lock: version 2.13.c.5'
	printf '#!/bin/sh\nexit 1\n' >"$BATS_TEST_TMPDIR/bin/magick"
	chmod +x "$BATS_TEST_TMPDIR/bin/magick"
	XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache" run "$LOCK"
	[[ $(cat "$ARGS") == *"--blur 8"* ]]
	[[ $(cat "$ARGS") != *"--image"* ]]
}

@test "plain i3lock gets the background colour" {
	fake i3lock 'i3lock: version 2.15'
	run "$LOCK"
	[ "$(cat "$ARGS")" = "--nofork --ignore-empty-password --show-failed-attempts --color 1f1f28" ]
}

@test "Wayland uses swaylock" {
	fake swaylock 'swaylock version 1.8'
	WAYLAND_DISPLAY=wayland-1 run "$LOCK"
	[[ $(cat "$ARGS") == "--color 1f1f28 "* ]]
}
