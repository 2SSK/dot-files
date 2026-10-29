#!/usr/bin/env bats
# ag and al (shell functions): AGENTS.md and LICENSE into the current project, never over an
# existing one.

setup() {
	export XDG_DATA_HOME="$BATS_TEST_DIRNAME/../.local/share"
	# shellcheck source=.config/shell/functions.sh
	source "$BATS_TEST_DIRNAME/../.config/shell/functions.sh"
	cd "$BATS_TEST_TMPDIR" || return
}

@test "ag adds AGENTS.md, and won't replace one" {
	run ag
	[ "$status" -eq 0 ]
	cmp -s AGENTS.md "$XDG_DATA_HOME/templates/AGENTS.md"
	run ag
	[ "$status" -eq 1 ]
}

@test "al adds this year's LICENSE, and won't replace one" {
	run al
	[ "$status" -eq 0 ]
	grep -qx "Copyright (c) $(date +%Y) Saurav Singh Karmwar" LICENSE
	run al
	[ "$status" -eq 1 ]
}
