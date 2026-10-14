#!/usr/bin/env bats
# desktop-displays: connected screens arranged as on sway (externals to the right of the laptop
# panel), unplugged ones turned off. A fake xrandr answers from $XRANDR and records what it's told.

setup() {
	D="$BATS_TEST_DIRNAME/../.local/bin/desktop-displays"
	export CALLS="$BATS_TEST_TMPDIR/calls" XRANDR="$BATS_TEST_TMPDIR/xrandr.txt"
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\nif [ "$1" = --query ]; then cat "$XRANDR"; else echo "xrandr $*" >>"$CALLS"; fi\n' >"$BATS_TEST_TMPDIR/bin/xrandr"
	printf '#!/bin/sh\necho "wallpaper $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/desktop-wallpaper"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH" DISPLAY=:0
}

@test "an external screen goes to the right of the laptop panel" {
	cat >"$XRANDR" <<'OUT'
Screen 0: minimum 320 x 200, current 1920 x 1200, maximum 16384 x 16384
eDP-1 connected primary 1920x1200+0+0 (normal left inverted right x axis y axis) 344mm x 215mm
   1920x1200     60.00*+
HDMI-1 connected (normal left inverted right x axis y axis)
   2560x1440     59.95 +
OUT
	run "$D" apply
	[ "$status" -eq 0 ]
	grep -qx "xrandr --output eDP-1 --auto --primary --pos 0x0 --output HDMI-1 --auto --right-of eDP-1" "$CALLS"
	grep -qx "wallpaper restore" "$CALLS"
}

@test "an unplugged screen that's still on is turned off" {
	cat >"$XRANDR" <<'OUT'
eDP-1 connected primary 1920x1200+0+0 (normal left inverted right x axis y axis) 344mm x 215mm
HDMI-1 disconnected 2560x1440+1920+0 (normal left inverted right x axis y axis) 0mm x 0mm
OUT
	"$D" apply
	grep -qx "xrandr --output eDP-1 --auto --primary --pos 0x0 --output HDMI-1 --off" "$CALLS"
}

@test "two externals line up to the right, one after the other" {
	cat >"$XRANDR" <<'OUT'
eDP-1 connected primary 1920x1200+0+0 (normal left inverted right x axis y axis) 344mm x 215mm
DP-1 connected (normal left inverted right x axis y axis)
HDMI-1 connected (normal left inverted right x axis y axis)
OUT
	"$D" apply
	grep -qx "xrandr --output eDP-1 --auto --primary --pos 0x0 --output DP-1 --auto --right-of eDP-1 --output HDMI-1 --auto --right-of DP-1" "$CALLS"
}

@test "without X it does nothing" {
	DISPLAY="" run "$D" apply
	[ "$status" -eq 0 ]
	[ ! -e "$CALLS" ]
}

# rehome: a fake swaymsg answers with the screens and workspaces and records the commands
rehome_fakes() { # <outputs json> <workspaces json>
	printf '%s' "$1" >"$BATS_TEST_TMPDIR/outputs.json"
	printf '%s' "$2" >"$BATS_TEST_TMPDIR/workspaces.json"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\ncase "$*" in *get_outputs*) cat "$BATS_TEST_TMPDIR/outputs.json" ;; *get_workspaces*) cat "$BATS_TEST_TMPDIR/workspaces.json" ;; *) echo "swaymsg $*" >>"$CALLS" ;; esac\n' >"$BATS_TEST_TMPDIR/bin/swaymsg"
	chmod +x "$BATS_TEST_TMPDIR/bin/swaymsg"
	mkdir -p "$BATS_TEST_TMPDIR/conf"
	printf 'workspace 1 output HDMI-A-1 DP-1 eDP-1\nworkspace 2 output HDMI-A-1 DP-1 eDP-1\nworkspace 6 output eDP-1\n' >"$BATS_TEST_TMPDIR/conf/workspaces.conf"
	export DESKTOP_WORKSPACES_CONF="$BATS_TEST_TMPDIR/conf/workspaces.conf" SWAYSOCK=/x
}

@test "rehome: a workspace left on the panel goes back to the monitor that came back, focus kept" {
	rehome_fakes '[{"name":"eDP-1","active":true},{"name":"HDMI-A-1","active":true}]' \
		'[{"num":1,"name":"1","output":"eDP-1","focused":false},{"num":2,"name":"2","output":"HDMI-A-1","focused":true},{"num":6,"name":"6","output":"eDP-1","focused":false}]'
	run "$D" rehome
	[ "$status" -eq 0 ]
	grep -qx 'swaymsg -q workspace number 1; move workspace to output HDMI-A-1' "$CALLS"
	! grep -q 'number 6' "$CALLS"
	[ "$(tail -1 "$CALLS")" = 'swaymsg -q workspace number 2' ]
}

@test "rehome: nothing to move, nothing done; a screen that's off doesn't count" {
	rehome_fakes '[{"name":"eDP-1","active":true},{"name":"HDMI-A-1","active":false}]' \
		'[{"num":1,"name":"1","output":"eDP-1","focused":true}]'
	run "$D" rehome
	[ "$status" -eq 0 ]
	[ ! -e "$CALLS" ]
}
