#!/usr/bin/env bats
# desktop-capture: screenshots and recordings of a region, the focused window or a screen. Fake
# tools record what they were asked; slop answers $REGION (or fails as if cancelled).

setup() {
	CAPTURE="$BATS_TEST_DIRNAME/../.local/bin/desktop-capture"
	export CALLS="$BATS_TEST_TMPDIR/calls" REGION="640x480+10+20" HOME="$BATS_TEST_TMPDIR/home"
	export XDG_PICTURES_DIR="$HOME/Pictures"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin" "$HOME"
	# maim and grim write a tiny file where they're told (their last argument)
	for tool in maim grim; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\nfor last; do :; done\necho png >"$last"\n' "$tool" >"$bin/$tool"
	done
	for tool in gpu-screen-recorder notify-send swaymsg; do
		# shellcheck disable=SC2016
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$bin/$tool"
	done
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "xclip $*" >>"$CALLS"\ncat >/dev/null\n' >"$bin/xclip"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "wl-copy $*" >>"$CALLS"\ncat >/dev/null\n' >"$bin/wl-copy"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\n[ -n "$REGION" ] || exit 1\necho "$REGION"\n' >"$bin/slop"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\n[ -n "$REGION" ] || exit 1\necho "10,20 640x480"\n' >"$bin/slurp"
	printf '#!/bin/sh\necho 4194311\n' >"$bin/xdotool"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
	unset WAYLAND_DISPLAY
}

shot_file() { ls "$XDG_PICTURES_DIR"/Screenshots/*.png; }

@test "a region shot: picked with slop, saved and copied as an image" {
	run "$CAPTURE" shot region
	[ "$status" -eq 0 ]
	grep -q "^maim -u -g 640x480+10+20 $XDG_PICTURES_DIR/Screenshots/Screenshot " "$CALLS"
	grep -qx "xclip -selection clipboard -t image/png" "$CALLS"
	[ -s "$(shot_file)" ]
	grep -q "^notify-send .*Screenshot copied" "$CALLS"
}

@test "a cancelled region saves and copies nothing" {
	REGION="" run "$CAPTURE" shot region
	[ "$status" -eq 1 ]
	! grep -q "^maim\|^xclip" "$CALLS" 2>/dev/null
}

@test "a window shot takes the focused window" {
	"$CAPTURE" shot window
	grep -q "^maim -u -i 4194311 " "$CALLS"
}

@test "a screen shot takes the chosen monitor, or everything" {
	"$CAPTURE" shot screen --monitor HDMI-1 --geometry 1920x1080+1920+0
	"$CAPTURE" shot screen
	[ "$(grep -c '^maim' "$CALLS")" -eq 2 ]
	grep -q "^maim -u -g 1920x1080+1920+0 " "$CALLS"
	grep -q "^maim -u $XDG_PICTURES_DIR" "$CALLS"
}

@test "recording a region, a window and a monitor" {
	"$CAPTURE" record region "$HOME/a.mp4"
	"$CAPTURE" record window "$HOME/b.mp4"
	"$CAPTURE" record screen "$HOME/c.mp4" --monitor DP-2
	grep -q "^gpu-screen-recorder -w region -region 640x480+10+20 -f 60 -a default_output -o $HOME/a.mp4" "$CALLS"
	grep -q "^gpu-screen-recorder -w 4194311 -f 60 -a default_output -o $HOME/b.mp4" "$CALLS"
	grep -q "^gpu-screen-recorder -w DP-2 -f 60 -a default_output -o $HOME/c.mp4" "$CALLS"
}

@test "recording the whole screen without a monitor" {
	run "$CAPTURE" record screen "$HOME/d.mp4"
	[ "${lines[0]}" = recording ]
	grep -q "^gpu-screen-recorder -w screen -f 60 -a default_output -o $HOME/d.mp4" "$CALLS"
}

@test "Wayland: grim and slurp; a window records through the portal" {
	export WAYLAND_DISPLAY=wayland-1
	"$CAPTURE" shot region
	"$CAPTURE" shot screen --monitor eDP-1 --geometry 1920x1200+0+0
	"$CAPTURE" record window "$HOME/e.mp4"
	grep -q "^grim -g 10,20 640x480 " "$CALLS"
	grep -q "^grim -o eDP-1 " "$CALLS"
	grep -q "^wl-copy --type image/png" "$CALLS"
	grep -q "^gpu-screen-recorder -w portal " "$CALLS"
}

@test "bad usage exits 2" {
	run "$CAPTURE" shot sideways
	[ "$status" -eq 2 ]
	run "$CAPTURE" record region
	[ "$status" -eq 2 ]
}
