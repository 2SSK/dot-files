#!/usr/bin/env bats
# desktop-wallpaper, with fake feh/magick/swaymsg recording what they're asked.

setup() {
	WALL="$BATS_TEST_DIRNAME/../.local/bin/desktop-wallpaper"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/pics"
	for tool in feh swaymsg; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$BATS_TEST_TMPDIR/bin/$tool"
	done
	# magick: a frame file for its last argument
	# shellcheck disable=SC2016
	printf '#!/bin/sh\nfor last; do :; done\necho frame >"$last"\necho "magick" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/magick"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
	unset WAYLAND_DISPLAY
	echo a >"$BATS_TEST_TMPDIR/pics/a.jpg"
	echo b >"$BATS_TEST_TMPDIR/pics/b.jpg"
}

@test "set: fades through blended frames to the new one, then remembers it" {
	"$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	rm "$CALLS"
	run "$WALL" set "$BATS_TEST_TMPDIR/pics/b.jpg"
	[ "$status" -eq 0 ]
	[ "$(grep -c '^magick' "$CALLS")" -eq 3 ]
	[ "$(grep -c '^feh' "$CALLS")" -eq 4 ]
	[ "$(tail -1 "$CALLS")" = "feh --no-fehbg --bg-fill $BATS_TEST_TMPDIR/pics/b.jpg" ]
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/b.jpg" ]
	[ -s "$XDG_STATE_HOME/desktop/wallpaper-changed" ]
}

@test "restore: draws the remembered one without a fade" {
	"$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	rm "$CALLS"
	run "$WALL" restore
	[ "$(cat "$CALLS")" = "feh --no-fehbg --bg-fill $BATS_TEST_TMPDIR/pics/a.jpg" ]
}

@test "Wayland without swww uses sway's background" {
	WAYLAND_DISPLAY=wayland-1 run "$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	grep -q "swaymsg -q output \* bg $BATS_TEST_TMPDIR/pics/a.jpg fill" "$CALLS"
	! grep -q '^magick' "$CALLS"
}

@test "set refuses what isn't a file" {
	run "$WALL" set "$BATS_TEST_TMPDIR/pics/missing.jpg"
	[ "$status" -eq 2 ]
}
