#!/usr/bin/env bats
# The shell's Hindu month, season and Hindi date (Panchang.js), checked with node.

@test "the month and season match the festivals, the Hindi date and the greeting read right" {
	command -v node >/dev/null || skip "node not installed"
	run node "$BATS_TEST_DIRNAME/panchang.js" "$BATS_TEST_DIRNAME/../.config/quickshell/desktop/Panchang.js"
	[ "$status" -eq 0 ] || { echo "$output"; false; }
}
