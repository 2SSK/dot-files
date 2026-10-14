#!/usr/bin/env bats
# desktop-power (the shell's power profile and charge limit) and desktop-charge-limit (root's side
# of the limit). Fakes: TLP's state and the battery under a scratch root; sudo -n and pkexec run
# the command or refuse, and record it.

setup() {
	POWER="$BATS_TEST_DIRNAME/../.local/bin/desktop-power"
	LIMIT="$BATS_TEST_DIRNAME/../system/usr/local/bin/desktop-charge-limit"
	export CALLS="$BATS_TEST_TMPDIR/calls" DESKTOP_POWER_ROOT="$BATS_TEST_TMPDIR/root"
	mkdir -p "$DESKTOP_POWER_ROOT/run/tlp" "$DESKTOP_POWER_ROOT/sys/class/power_supply/BAT1" "$DESKTOP_POWER_ROOT/etc/tlp.d"
	echo "1 0" >"$DESKTOP_POWER_ROOT/run/tlp/last_pwr"
	echo 85 >"$DESKTOP_POWER_ROOT/sys/class/power_supply/BAT1/charge_control_end_threshold"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "sudo $*" >>"$CALLS"\n[ -e "$BATS_TEST_TMPDIR/no-rule" ] && exit 1\nshift\n"$@"\n' >"$bin/sudo"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "pkexec $*" >>"$CALLS"\n"$@"\n' >"$bin/pkexec"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "tlp $*" >>"$CALLS"\n' >"$bin/tlp"
	ln -s "$LIMIT" "$bin/desktop-charge-limit"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH" BATS_TEST_TMPDIR
}

@test "state: TLP's profile and the battery's charge limit, as JSON" {
	run "$POWER" state
	[ "$status" -eq 0 ]
	[ "$(jq -r .profile <<<"$output")" = balanced ]
	[ "$(jq -r .limit <<<"$output")" = 85 ]
	echo "2 1" >"$DESKTOP_POWER_ROOT/run/tlp/last_pwr"
	[ "$("$POWER" state | jq -r .profile)" = power-saver ]
	echo "0 0" >"$DESKTOP_POWER_ROOT/run/tlp/last_pwr"
	[ "$("$POWER" state | jq -r .profile)" = performance ]
}

@test "state: without TLP or a battery, both are empty" {
	rm -r "$DESKTOP_POWER_ROOT/run/tlp" "$DESKTOP_POWER_ROOT/sys/class/power_supply/BAT1"
	run "$POWER" state
	[ "$status" -eq 0 ]
	[ "$(jq -r .profile <<<"$output")" = "" ]
	[ "$(jq -r .limit <<<"$output")" = 0 ]
}

@test "profile: through sudo -n, else pkexec asks" {
	run "$POWER" profile performance
	[ "$status" -eq 0 ]
	grep -qx "sudo -n tlp performance" "$CALLS"
	touch "$BATS_TEST_TMPDIR/no-rule"
	run "$POWER" profile power-saver
	[ "$status" -eq 0 ]
	grep -qx "pkexec tlp power-saver" "$CALLS"
}

@test "profile: anything but TLP's three is refused" {
	run "$POWER" profile turbo
	[ "$status" -eq 2 ]
	[ ! -e "$CALLS" ]
}

@test "limit: through the root helper, which keeps it for TLP and sets the battery now" {
	run "$POWER" limit 60
	[ "$status" -eq 0 ]
	grep -qx "sudo -n desktop-charge-limit 60" "$CALLS"
	[ "$(cat "$DESKTOP_POWER_ROOT/sys/class/power_supply/BAT1/charge_control_end_threshold")" = 60 ]
	grep -qx 'STOP_CHARGE_THRESH_BAT0=60' "$DESKTOP_POWER_ROOT/etc/tlp.d/20-charge-limit.conf"
	grep -qx 'STOP_CHARGE_THRESH_BAT1=60' "$DESKTOP_POWER_ROOT/etc/tlp.d/20-charge-limit.conf"
	grep -qx 'START_CHARGE_THRESH_BAT1=0' "$DESKTOP_POWER_ROOT/etc/tlp.d/20-charge-limit.conf"
}

@test "limit: only whole percentages from 50 to 100" {
	local bad
	for bad in 49 101 070 abc 80.5 "" "85; rm -rf /"; do
		run "$LIMIT" "$bad"
		[ "$status" -eq 2 ] || { echo "accepted: $bad" && false; }
	done
	[ ! -e "$DESKTOP_POWER_ROOT/etc/tlp.d/20-charge-limit.conf" ]
	run "$POWER" limit 120
	[ "$status" -eq 2 ]
}
