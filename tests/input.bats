#!/usr/bin/env bats
# desktop-input: the touchpad set up on X11 as sway's input config does, through a fake xinput.

setup() {
	INPUT="$BATS_TEST_DIRNAME/../.local/bin/desktop-input"
	export CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	# xinput: a touchpad (10) and a mouse (9); set-prop calls are recorded
	# shellcheck disable=SC2016 # expands when the fake runs
	cat >"$BATS_TEST_TMPDIR/bin/xinput" <<'FAKE'
#!/bin/sh
case $1 in
list) [ "$2" = --id-only ] && printf '2\n4\n9\n10\n' ;;
list-props)
	[ "$2" = 10 ] && echo '	libinput Tapping Enabled (361):	0' && echo '	libinput Scrolling Pixel Distance (358):	15'
	[ "$2" = 9 ] && echo '	libinput Accel Speed (343):	0.000000' ;;
set-prop) echo "set-prop $*" >>"$CALLS" ;;
esac
FAKE
	chmod +x "$BATS_TEST_TMPDIR/bin/xinput"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH" DISPLAY=:0
}

@test "a touchpad gets tap, natural two-finger scrolling, clickfinger and a slower scroll" {
	run "$INPUT"
	[ "$status" -eq 0 ]
	grep -qx 'set-prop set-prop 10 libinput Tapping Enabled 1' "$CALLS"
	grep -qx 'set-prop set-prop 10 libinput Natural Scrolling Enabled 1' "$CALLS"
	grep -qx 'set-prop set-prop 10 libinput Scroll Method Enabled 1 0 0' "$CALLS"
	grep -qx 'set-prop set-prop 10 libinput Click Method Enabled 0 1' "$CALLS"
	grep -qx 'set-prop set-prop 10 libinput Middle Emulation Enabled 1' "$CALLS"
	grep -qx 'set-prop set-prop 10 libinput Scrolling Pixel Distance 30' "$CALLS"
}

@test "devices that aren't touchpads are left alone" {
	"$INPUT"
	! grep -q 'set-prop 9 ' "$CALLS"
	! grep -q 'set-prop 2 \|set-prop 4 ' "$CALLS"
}

@test "the scroll distance can be changed" {
	DESKTOP_SCROLL_DISTANCE=45 "$INPUT"
	grep -qx 'set-prop set-prop 10 libinput Scrolling Pixel Distance 45' "$CALLS"
}

@test "without X it does nothing" {
	DISPLAY="" run "$INPUT"
	[ "$status" -eq 0 ]
	[ ! -e "$CALLS" ]
}
