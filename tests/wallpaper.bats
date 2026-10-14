#!/usr/bin/env bats
# desktop-wallpaper, with fake feh/magick/swaymsg recording what they're asked.

setup() {
	# never the real login screen (system.sh shares their backgrounds and colours with us)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/no-sddm"
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

@test "Wayland: remembered and announced, drawn by nothing here (the shell's background layer fades it in)" {
	WAYLAND_DISPLAY=wayland-1 run "$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	[ "$status" -eq 0 ]
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/a.jpg" ]
	[ -s "$XDG_STATE_HOME/desktop/wallpaper-changed" ] # what the shell watches
	! grep -q '^swaymsg\|^feh\|^magick' "$CALLS"
	WAYLAND_DISPLAY=wayland-1 run "$WALL" restore
	[ "$status" -eq 0 ]
	! grep -q '^swaymsg\|^feh' "$CALLS"
}

@test "set refuses what isn't a file" {
	run "$WALL" set "$BATS_TEST_TMPDIR/pics/missing.jpg"
	[ "$status" -eq 2 ]
}

screens_fakes() { # the folder system.sh shares with sddm (a folder of ours)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/sddm"
	mkdir -p "$DESKTOP_SDDM_DIR" "$XDG_STATE_HOME/desktop"
	echo old >"$DESKTOP_SDDM_DIR/background.jpg"
	# magick: what it was asked, and a file where it was told
	# shellcheck disable=SC2016
	printf '#!/bin/sh\nfor last; do :; done\necho "magick $*" >>"$CALLS"\necho new >"$last"\n' >"$BATS_TEST_TMPDIR/bin/magick"
}

@test "screens: the login screen gets the wallpaper" {
	screens_fakes
	ln -sfn "$BATS_TEST_TMPDIR/pics/b.jpg" "$XDG_STATE_HOME/desktop/wallpaper"
	run "$WALL" screens
	[ "$status" -eq 0 ]
	[ "$(cat "$DESKTOP_SDDM_DIR/background.jpg")" = new ]
	grep -q "^magick $BATS_TEST_TMPDIR/pics/b.jpg -resize 2560x2560> " "$CALLS"
	[ "$(wc -l <"$CALLS")" -eq 1 ] # nothing for a boot menu
	[ -z "$(find "$DESKTOP_SDDM_DIR" -name '.*')" ] # no temporary files left
}

@test "screens: a folder that isn't ours is left alone" {
	screens_fakes
	chmod a-w "$DESKTOP_SDDM_DIR"
	run "$WALL" screens
	[ "$status" -eq 0 ]
	[ "$(cat "$DESKTOP_SDDM_DIR/background.jpg")" = old ]
	chmod u+w "$DESKTOP_SDDM_DIR"
}

@test "screens: no login screen set up, nothing to do" {
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/none"
	run "$WALL" screens
	[ "$status" -eq 0 ]
}

@test "set: the login screen follows the new wallpaper" {
	screens_fakes
	run "$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	[ "$status" -eq 0 ]
	[ "$(cat "$DESKTOP_SDDM_DIR/background.jpg")" = new ]
}

next_boot_fakes() { # shell.json rotating at boot over the pictures, a shutdown under way, sddm's folder
	unset XDG_CONFIG_HOME
	export HOME="$BATS_TEST_TMPDIR/home" DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/sddm" SYSTEM_STATE=stopping
	mkdir -p "$HOME/.config/desktop" "$XDG_STATE_HOME/desktop" "$DESKTOP_SDDM_DIR"
	printf '{"wallpaper": {"folders": ["%s"], "rotate": "%s"}}\n' "$BATS_TEST_TMPDIR/pics" "${1:-boot}" \
		>"$HOME/.config/desktop/shell.json"
	ln -sfn "$BATS_TEST_TMPDIR/pics/a.jpg" "$XDG_STATE_HOME/desktop/wallpaper"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\n[ "$1" = is-system-running ] && echo "$SYSTEM_STATE"\n' >"$BATS_TEST_TMPDIR/bin/systemctl"
	chmod +x "$BATS_TEST_TMPDIR/bin/systemctl"
}

@test "next-boot: while shutting down, a different wallpaper for the next boot, the login screen's too" {
	next_boot_fakes
	run "$WALL" next-boot
	[ "$status" -eq 0 ]
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/b.jpg" ]
	[ -s "$XDG_STATE_HOME/desktop/wallpaper-changed" ]
	[ "$(cat "$DESKTOP_SDDM_DIR/background.jpg")" = frame ] # redrawn for the login screen
	! grep -q '^feh\|^swaymsg' "$CALLS" # nothing drawn: the display is going away
}

@test "next-boot: a logout (no shutdown) keeps the wallpaper" {
	next_boot_fakes
	SYSTEM_STATE=running run "$WALL" next-boot
	[ "$status" -eq 0 ]
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/a.jpg" ]
}

@test "next-boot: only when the rotation is set to boot" {
	next_boot_fakes 1h
	run "$WALL" next-boot
	[ "$status" -eq 0 ]
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/a.jpg" ]
}

@test "next-boot: from the theme's folder when it has more than one" {
	next_boot_fakes
	mkdir -p "$BATS_TEST_TMPDIR/pics/nord" "$XDG_STATE_HOME/desktop/theme"
	echo x >"$BATS_TEST_TMPDIR/pics/nord/x.png" && echo y >"$BATS_TEST_TMPDIR/pics/nord/y.png"
	printf 'family=nord\nmode=dark\n' >"$XDG_STATE_HOME/desktop/theme/current"
	ln -sfn "$BATS_TEST_TMPDIR/pics/nord/x.png" "$XDG_STATE_HOME/desktop/wallpaper"
	run "$WALL" next-boot
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/nord/y.png" ]
}
