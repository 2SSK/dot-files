#!/usr/bin/env bats
# log.sh: quiet by default (warnings and errors only); DESKTOP_LOG_LEVEL shows more.

setup() {
	# shellcheck source=.local/lib/desktop/log.sh
	source "$BATS_TEST_DIRNAME/../.local/lib/desktop/log.sh"
	unset DESKTOP_LOG_LEVEL
}

@test "info is hidden by default; warn and error print" {
	run log_info built name=x
	[ -z "$output" ]
	run log_warn moved_aside path=/x
	[ "$output" = "level=warn event=moved_aside path=/x" ]
	run log_error broken
	[ "$output" = "level=error event=broken" ]
}

@test "DESKTOP_LOG_LEVEL=info shows info, debug stays hidden" {
	DESKTOP_LOG_LEVEL=info run log_info built name=x
	[ "$output" = "level=info event=built name=x" ]
	DESKTOP_LOG_LEVEL=info run log debug detail
	[ -z "$output" ]
}

@test "die still prints its error and exits 1" {
	run die no_vm name=x
	[ "$status" -eq 1 ]
	[ "$output" = "level=error event=no_vm name=x" ]
}
