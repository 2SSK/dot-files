#!/usr/bin/env bats
# ag and al: AGENTS.md and LICENSE into the current project, never over an existing one.

setup() {
	export XDG_DATA_HOME="$BATS_TEST_DIRNAME/../.local/share"
	cd "$BATS_TEST_TMPDIR"
}

@test "ag adds AGENTS.md, and won't replace one" {
	run "$BATS_TEST_DIRNAME/../.local/bin/ag"
	[ "$status" -eq 0 ]
	cmp -s AGENTS.md "$XDG_DATA_HOME/templates/AGENTS.md"
	run "$BATS_TEST_DIRNAME/../.local/bin/ag"
	[ "$status" -eq 1 ]
}

@test "al adds this year's LICENSE, and won't replace one" {
	run "$BATS_TEST_DIRNAME/../.local/bin/al"
	[ "$status" -eq 0 ]
	grep -qx "Copyright (c) $(date +%Y) Saurav Singh Karmwar" LICENSE
	run "$BATS_TEST_DIRNAME/../.local/bin/al"
	[ "$status" -eq 1 ]
}
