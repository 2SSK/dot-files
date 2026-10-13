#!/usr/bin/env bats
# desktop-effects: on SwayFX effects.conf is linked where sway's config includes it (and sway reloaded
# once to read it); on plain sway, whose config would refuse it, the link goes. A fake sway reports a
# version; a fake swaymsg records its calls.

setup() {
	E="$BATS_TEST_DIRNAME/../.local/bin/desktop-effects"
	export CALLS="$BATS_TEST_TMPDIR/calls" SWAYSOCK=/x XDG_CONFIG_HOME="$BATS_TEST_DIRNAME/../.config"
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	LINK="$XDG_STATE_HOME/desktop/sway-effects.conf"
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fakes run
	printf '#!/bin/sh\necho "$VERSION"\n' >"$BATS_TEST_TMPDIR/bin/sway"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "$*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/swaymsg"
	chmod +x "$BATS_TEST_TMPDIR/bin/sway" "$BATS_TEST_TMPDIR/bin/swaymsg"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "SwayFX: effects.conf linked into the config, sway reloaded once to read it" {
	VERSION="swayfx version 0.6 (based on sway 1.12.0)" run "$E"
	[ "$status" -eq 0 ]
	[ "$(readlink "$LINK")" = "$XDG_CONFIG_HOME/sway/effects.conf" ]
	[ "$(cat "$CALLS")" = "-q reload" ]
}

@test "SwayFX, already linked (each reload): nothing more, so no reload loop" {
	VERSION="swayfx version 0.6" run "$E"
	rm -f "$CALLS"
	VERSION="swayfx version 0.6" run "$E"
	[ "$status" -eq 0 ]
	[ ! -e "$CALLS" ]
}

@test "the config includes the link, through a glob that matches nothing on plain sway" {
	grep -qx 'include ~/.local/state/desktop/sway-effects\*.conf' "$XDG_CONFIG_HOME/sway/desktop.conf"
}

@test "plain sway: the link goes, and nothing is sent" {
	mkdir -p "${LINK%/*}" && ln -s /nowhere "$LINK"
	VERSION="sway version 1.11" run "$E"
	[ "$status" -eq 0 ]
	[ ! -L "$LINK" ]
	[ ! -e "$CALLS" ]
}
