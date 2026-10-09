#!/usr/bin/env bats
# desktop-idle: X's screensaver and DPMS timers from the settings (dim, lock, screen off), and the
# dim step xss-lock runs before locking. Fake xset and brightnessctl record what they're asked.

setup() {
	IDLE="$BATS_TEST_DIRNAME/../.local/bin/desktop-idle"
	export CALLS="$BATS_TEST_TMPDIR/calls" LEVEL="$BATS_TEST_TMPDIR/level"
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "xset $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/xset"
	# brightnessctl: get prints the level kept in $LEVEL; set records
	# shellcheck disable=SC2016
	printf '#!/bin/sh\n[ "$1" = -q ] && shift\ncase $1 in get) cat "$LEVEL" ;; max) echo 100 ;; set) echo "brightnessctl $*" >>"$CALLS"; echo "$2" >"$LEVEL" ;; esac\n' >"$BATS_TEST_TMPDIR/bin/brightnessctl"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH" DISPLAY=:0
	echo 80 >"$LEVEL"
}

teardown() {
	[ -z "${pid:-}" ] || kill -TERM "$pid" 2>/dev/null || true
}

@test "dim at 4, lock at 5, off at 10: the screensaver starts at 4 and locks a minute later" {
	run "$IDLE" apply 4 5 10
	[ "$status" -eq 0 ]
	grep -qx "xset s 240 60" "$CALLS"
	grep -qx "xset dpms 0 0 600" "$CALLS"
	grep -qx "xset +dpms" "$CALLS"
}

@test "no dim: the screensaver locks straight away at the lock time" {
	"$IDLE" apply 0 5 10
	grep -qx "xset s 300 0" "$CALLS"
}

@test "never lock, never off" {
	"$IDLE" apply 0 0 0
	grep -qx "xset s off" "$CALLS"
	grep -qx "xset -dpms" "$CALLS"
}

@test "dim fades the brightness down and puts it back when stopped" {
	"$IDLE" dim >/dev/null 2>&1 3>&- &
	pid=$!
	sleep 2.5
	[ "$(cat "$LEVEL")" -le 24 ] # faded to about a quarter of where it was
	kill -TERM "$pid"
	wait "$pid" || true
	[ "$(cat "$LEVEL")" = 80 ]
}
