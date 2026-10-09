#!/usr/bin/env bats
# desktop-wallpaper, with fake feh/magick/swaymsg recording what they're asked.

setup() {
	# never the real login screen or boot menu (system.sh shares their backgrounds and colours with us)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/no-sddm" DESKTOP_GRUB_DIR="$BATS_TEST_TMPDIR/no-grub"
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

screens_fakes() { # the folders system.sh shares: sddm's (a folder of ours), GRUB's (only its background is ours)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/sddm" DESKTOP_GRUB_DIR="$BATS_TEST_TMPDIR/grub"
	mkdir -p "$DESKTOP_SDDM_DIR" "$DESKTOP_GRUB_DIR" "$XDG_STATE_HOME/desktop/theme"
	echo old >"$DESKTOP_SDDM_DIR/background.jpg"
	echo old >"$DESKTOP_GRUB_DIR/background.jpg"
	printf '{\n  "ui": {\n    "bg": "#1f1f28",\n    "fg": "#dcd7ba"\n  }\n}\n' >"$XDG_STATE_HOME/desktop/theme/palette.json"
	# magick: what it was asked, and a file where it was told
	# shellcheck disable=SC2016
	printf '#!/bin/sh\nfor last; do :; done\necho "magick $*" >>"$CALLS"\necho new >"$last"\n' >"$BATS_TEST_TMPDIR/bin/magick"
}

@test "screens: the login screen gets the wallpaper, the boot menu it blurred in the theme's colour" {
	screens_fakes
	ln -sfn "$BATS_TEST_TMPDIR/pics/b.jpg" "$XDG_STATE_HOME/desktop/wallpaper"
	run "$WALL" screens
	[ "$status" -eq 0 ]
	[ "$(cat "$DESKTOP_SDDM_DIR/background.jpg")" = new ]
	[ "$(cat "$DESKTOP_GRUB_DIR/background.jpg")" = new ]
	grep -q "^magick $BATS_TEST_TMPDIR/pics/b.jpg -resize 2560x2560> " "$CALLS"
	grep -q "^magick $BATS_TEST_TMPDIR/pics/b.jpg .*-blur 0x24 .*xc:#1f1f28 " "$CALLS"
	[ -z "$(find "$DESKTOP_SDDM_DIR" "$DESKTOP_GRUB_DIR" -name '.*')" ] # no temporary files left
}

@test "screens: a background that isn't ours is left alone" {
	screens_fakes
	chmod a-w "$DESKTOP_GRUB_DIR/background.jpg" "$DESKTOP_SDDM_DIR"
	run "$WALL" screens
	[ "$status" -eq 0 ]
	[ "$(cat "$DESKTOP_SDDM_DIR/background.jpg")" = old ]
	[ "$(cat "$DESKTOP_GRUB_DIR/background.jpg")" = old ]
	chmod u+w "$DESKTOP_SDDM_DIR"
}

@test "set: the login screen and boot menu follow the new wallpaper" {
	screens_fakes
	run "$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	[ "$status" -eq 0 ]
	[ "$(cat "$DESKTOP_SDDM_DIR/background.jpg")" = new ]
	[ "$(cat "$DESKTOP_GRUB_DIR/background.jpg")" = new ]
}
