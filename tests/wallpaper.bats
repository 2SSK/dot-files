#!/usr/bin/env bats
# desktop wallpaper, with fake feh/magick/swaymsg/awww recording what they're asked (never the real
# ones: a real awww-daemon would draw on the live session).

setup() {
	# never the real login screen (system.sh shares their backgrounds and colours with us)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/no-sddm"
	WALL="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/wallpaper"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/pics"
	for tool in feh swaymsg swaybg; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$BATS_TEST_TMPDIR/bin/$tool"
	done
	# magick: a frame file for its last argument
	# shellcheck disable=SC2016
	printf '#!/bin/sh\nfor last; do :; done\necho frame >"$last"\necho "magick" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/magick"
	# awww: up once its daemon has started; awww-daemon starts it
	{
		printf '#!/bin/sh\necho "awww $*" >>"$CALLS"\n[ "$1" != query ] || [ -e "$BATS_TEST_TMPDIR/up" ]\n' >"$BATS_TEST_TMPDIR/bin/awww"
		printf '#!/bin/sh\necho "awww-daemon $*" >>"$CALLS"\ntouch "$BATS_TEST_TMPDIR/up"\n' >"$BATS_TEST_TMPDIR/bin/awww-daemon"
	}
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

@test "wayland: awww fades to a new one, restores without a fade, its daemon started when it isn't up" {
	export WAYLAND_DISPLAY=wayland-test
	"$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	grep -qx "awww-daemon --no-cache" "$CALLS" # its cache would cover the new one at login
	grep -q "^awww img $BATS_TEST_TMPDIR/pics/a.jpg --transition-type fade" "$CALLS"
	run grep -q "^feh\|^magick" "$CALLS"
	[ "$status" -ne 0 ]
	rm "$CALLS"
	"$WALL" restore
	run grep -q "^awww-daemon" "$CALLS"
	[ "$status" -ne 0 ] # already up
	grep -q "^awww img $BATS_TEST_TMPDIR/pics/a.jpg --transition-type none" "$CALLS"
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/a.jpg" ]
}

# live wallpapers: fake mpvpaper, pkill and ffmpeg record what they're asked; the player starts in
# the background, so the tests wait for it
live_fakes() {
	export WAYLAND_DISPLAY=wayland-test XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
	export DESKTOP_LIVE_SOCKET="$BATS_TEST_TMPDIR/live.sock"
	for tool in mpvpaper pkill; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$BATS_TEST_TMPDIR/bin/$tool"
	done
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "ffmpeg $*" >>"$CALLS"\nfor last; do :; done\necho jpg >"$last"\n' >"$BATS_TEST_TMPDIR/bin/ffmpeg"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	echo v >"$BATS_TEST_TMPDIR/pics/rain.mp4"
	echo g >"$BATS_TEST_TMPDIR/pics/fire.gif"
}

played() { # waits for the player to be started with <file>
	for _ in $(seq 50); do grep -q "^mpvpaper .* ALL $1$" "$CALLS" 2>/dev/null && return 0; sleep 0.05; done
	return 1
}

@test "live: plays a file muted and looped over every screen, and remembers it" {
	live_fakes
	run "$WALL" live "$BATS_TEST_TMPDIR/pics/rain.mp4"
	[ "$status" -eq 0 ]
	played "$BATS_TEST_TMPDIR/pics/rain.mp4"
	grep -q "^mpvpaper -o no-audio loop hwdec=auto panscan=1.0 input-ipc-server=$DESKTOP_LIVE_SOCKET ALL " "$CALLS"
	grep -qx "pkill -x mpvpaper" "$CALLS" # never two at once
	[ "$(readlink "$XDG_STATE_HOME/desktop/live-wallpaper")" = "$BATS_TEST_TMPDIR/pics/rain.mp4" ]
}

@test "live off: stops it and forgets it; the still wallpaper is left as it was" {
	live_fakes
	"$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	"$WALL" live "$BATS_TEST_TMPDIR/pics/fire.gif"
	rm "$CALLS"
	run "$WALL" live off
	[ "$status" -eq 0 ]
	grep -qx "pkill -x mpvpaper" "$CALLS"
	[ ! -e "$XDG_STATE_HOME/desktop/live-wallpaper" ]
	[ "$(readlink "$XDG_STATE_HOME/desktop/wallpaper")" = "$BATS_TEST_TMPDIR/pics/a.jpg" ]
}

@test "restore: the still one, then the remembered live one plays again" {
	live_fakes
	"$WALL" set "$BATS_TEST_TMPDIR/pics/a.jpg"
	rm "$CALLS"
	"$WALL" restore
	sleep 0.3
	run grep -c "^mpvpaper" "$CALLS"
	[ "$output" = 0 ] # no live one chosen
	"$WALL" live "$BATS_TEST_TMPDIR/pics/rain.mp4"
	rm "$CALLS"
	"$WALL" restore
	grep -q "^awww img $BATS_TEST_TMPDIR/pics/a.jpg " "$CALLS"
	played "$BATS_TEST_TMPDIR/pics/rain.mp4"
}

@test "live pause and resume: told to the player over its socket" {
	live_fakes
	python3 -I -c '
import socket, sys
s = socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]); s.listen(); s.settimeout(5)
with open(sys.argv[2], "a") as out:
    for _ in range(2):
        c, _ = s.accept(); out.write(c.recv(200).decode()); out.flush(); c.close()
' "$DESKTOP_LIVE_SOCKET" "$BATS_TEST_TMPDIR/said" &
	for _ in $(seq 50); do [ -S "$DESKTOP_LIVE_SOCKET" ] && break; sleep 0.05; done
	"$WALL" live pause
	"$WALL" live resume
	wait
	[ "$(sed -n 1p "$BATS_TEST_TMPDIR/said")" = '{"command": ["set_property", "pause", true]}' ]
	[ "$(sed -n 2p "$BATS_TEST_TMPDIR/said")" = '{"command": ["set_property", "pause", false]}' ]
}

@test "live pause with nothing playing does nothing" {
	live_fakes
	run "$WALL" live pause
	[ "$status" -eq 0 ]
}

@test "live: X11, or no mpvpaper, says so and remembers nothing" {
	live_fakes
	WAYLAND_DISPLAY="" run "$WALL" live "$BATS_TEST_TMPDIR/pics/rain.mp4"
	[ "$status" -eq 1 ]
	[[ $output == *sway* ]]
	DESKTOP_LIVE_PLAYER=no-such-player run "$WALL" live "$BATS_TEST_TMPDIR/pics/rain.mp4"
	[ "$status" -eq 1 ]
	[[ $output == *mpvpaper* ]]
	[ ! -e "$XDG_STATE_HOME/desktop/live-wallpaper" ]
}

@test "thumbs: a small picture per wallpaper for the picker, made once; GIFs need none" {
	live_fakes
	run "$WALL" thumbs "$BATS_TEST_TMPDIR/pics/rain.mp4" "$BATS_TEST_TMPDIR/pics/fire.gif" "$BATS_TEST_TMPDIR/pics/a.jpg"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[[ ${lines[0]} == "$BATS_TEST_TMPDIR/pics/rain.mp4"$'\t'"$XDG_CACHE_HOME/desktop/wallpaper-thumbs/"*.jpg ]]
	[[ ${lines[1]} == "$BATS_TEST_TMPDIR/pics/a.jpg"$'\t'"$XDG_CACHE_HOME/desktop/wallpaper-thumbs/"*.jpg ]]
	[ -s "${lines[0]#*$'\t'}" ]
	[ -s "${lines[1]#*$'\t'}" ]
	[ "$(grep -c '^ffmpeg' "$CALLS")" -eq 1 ] # a video's frame
	[ "$(grep -c '^magick' "$CALLS")" -eq 1 ] # a still, made small
	"$WALL" thumbs "$BATS_TEST_TMPDIR/pics/rain.mp4" "$BATS_TEST_TMPDIR/pics/a.jpg"
	[ "$(grep -c '^ffmpeg\|^magick' "$CALLS")" -eq 2 ] # not again
	touch -d '+1 min' "$BATS_TEST_TMPDIR/pics/a.jpg" # an edited file gets a new one
	"$WALL" thumbs "$BATS_TEST_TMPDIR/pics/a.jpg"
	[ "$(grep -c '^magick' "$CALLS")" -eq 2 ]
}
