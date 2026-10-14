#!/usr/bin/env bats
# desktop-paste: the clipboard pasted into the focused window, with the key that window pastes on
# (terminals Ctrl+Shift+V, everything else Ctrl+V; an image into a terminal Ctrl+V too). Fakes:
# swaymsg/xdotool report a focused app, wl-paste/xclip the clipboard's types ($TYPES; never the real
# clipboard), wtype/xdotool record the keys.

setup() {
	P="$BATS_TEST_DIRNAME/../.local/bin/desktop-paste"
	export CALLS="$BATS_TEST_TMPDIR/calls" APP=kitty DESKTOP_PASTE_DELAY=0 TYPES="text/plain;charset=utf-8"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "{\\"nodes\\":[{\\"focused\\":true,\\"app_id\\":\\"$APP\\",\\"nodes\\":[],\\"floating_nodes\\":[]}],\\"floating_nodes\\":[]}"\n' >"$bin/swaymsg"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "wtype $*" >>"$CALLS"\n' >"$bin/wtype"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "$TYPES"\n' | tee "$bin/wl-paste" >"$bin/xclip"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\ncase "$1" in getactivewindow) echo "$APP" ;; *) echo "xdotool $*" >>"$CALLS" ;; esac\n' >"$bin/xdotool"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
}

@test "sway: a terminal gets Ctrl+Shift+V" {
	WAYLAND_DISPLAY=wayland-1 SWAYSOCK=/x run "$P"
	[ "$status" -eq 0 ]
	grep -qx "wtype -M ctrl -M shift -k v -m shift -m ctrl" "$CALLS"
}

@test "sway: anything else gets Ctrl+V" {
	APP=brave-browser WAYLAND_DISPLAY=wayland-1 SWAYSOCK=/x run "$P"
	grep -qx "wtype -M ctrl -k v -m ctrl" "$CALLS"
}

@test "i3: xdotool, by the window's class" {
	APP=Alacritty DISPLAY=:0 run env -u WAYLAND_DISPLAY -u SWAYSOCK "$P"
	grep -qx "xdotool key --clearmodifiers ctrl+shift+v" "$CALLS"
	APP=firefox DISPLAY=:0 run env -u WAYLAND_DISPLAY -u SWAYSOCK "$P"
	grep -qx "xdotool key --clearmodifiers ctrl+v" "$CALLS"
}

@test "an image goes into a terminal on Ctrl+V: the terminal pastes only text, Claude Code reads the image" {
	TYPES=image/png WAYLAND_DISPLAY=wayland-1 SWAYSOCK=/x run "$P"
	grep -qx "wtype -M ctrl -k v -m ctrl" "$CALLS"
	rm "$CALLS"
	TYPES=image/png APP=Alacritty DISPLAY=:0 run env -u WAYLAND_DISPLAY -u SWAYSOCK "$P"
	grep -qx "xdotool key --clearmodifiers ctrl+v" "$CALLS"
}
