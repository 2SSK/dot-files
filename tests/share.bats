#!/usr/bin/env bats
# .local/bin/desktop-share-pick, the portal's screen-sharing picker: a fake qs stands in for the shell,
# answering through the FIFO the way the capture panel does (or not running at all).

setup() {
	PICK="$BATS_TEST_DIRNAME/../.local/bin/desktop-share-pick"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	export PATH="$bin:$PATH" SOURCES=$'Monitor: eDP-1 Chimei Innolux 0x1618\nWindow: Teams (meeting) (4f2a)'
}

fake_qs() { # <answer>: the shell picks it (printed into the FIFO, as Share.answer does)
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\ncp "$7/sources" "%s/seen"\n(printf "%%s\\n" "%s" >"$7/answer") &\n' "$BATS_TEST_TMPDIR" "$1" >"$bin/qs"
	chmod +x "$bin/qs"
}

@test "the shell's pick goes back to the portal, which handed it every source" {
	fake_qs 'Window: Teams (meeting) (4f2a)'
	run "$PICK" <<<"$SOURCES"
	[ "$status" -eq 0 ]
	[ "$output" = 'Window: Teams (meeting) (4f2a)' ]
	[ "$(cat "$BATS_TEST_TMPDIR/seen")" = "$SOURCES" ]
}

@test "declined in the shell: nothing printed" {
	fake_qs ''
	run "$PICK" <<<"$SOURCES"
	[ "$output" = "" ]
}

@test "no shell running: the first screen is shared" {
	printf '#!/bin/sh\nexit 1\n' >"$bin/qs" && chmod +x "$bin/qs"
	run "$PICK" <<<"$SOURCES"
	[ "$output" = 'Monitor: eDP-1 Chimei Innolux 0x1618' ]
}
