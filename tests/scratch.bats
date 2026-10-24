#!/usr/bin/env bats
# desktop-scratch, the scratchpad as one floating workspace, with a fake swaymsg: $GROUP is none,
# hidden or shown; it records the commands it's given.

setup() {
	SCRATCH="$BATS_TEST_DIRNAME/../.local/bin/desktop-scratch"
	export CALLS="$BATS_TEST_TMPDIR/calls" SWAYSOCK=fake
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '%s\n' '#!/bin/sh' 'case "$1 $2" in' \
		'"-t get_marks") [ "$GROUP" = none ] && echo "[]" || echo "[\"_scratch_workspace\"]" ;;' \
		'"-t get_tree") if [ "$GROUP" = hidden ]; then echo "{\"name\":\"__i3_scratch\",\"floating_nodes\":[{\"marks\":[\"_scratch_workspace\"]}]}"; else echo "{\"nodes\":[{\"marks\":[\"_scratch_workspace\"]}]}"; fi ;;' \
		'*) shift; echo "$*" >>"$CALLS" ;;' 'esac' >"$bin/swaymsg"
	chmod +x "$bin/swaymsg"
	export PATH="$bin:$PATH"
}

@test "the first window makes the group: floating, tabbed, centred, then hidden" {
	GROUP=none run "$SCRATCH" add
	[ "$status" -eq 0 ]
	grep -q 'floating enable; split h; layout tabbed; focus parent; mark --add _scratch_workspace' "$CALLS"
	grep -q 'resize set width 80 ppt height 75 ppt.*move position center.*move scratchpad' "$CALLS"
}

@test "added while the group is hidden: it comes out for a moment, takes the window, and hides again" {
	GROUP=hidden run "$SCRATCH" add
	[ "$status" -eq 0 ]
	[ "$(sed -n 2p "$CALLS")" = '[con_mark="^_scratch_workspace$"] scratchpad show' ]
	grep -q 'move container to mark _scratch_workspace' "$CALLS"
	[ "$(tail -1 "$CALLS")" = '[con_mark="^_scratch_workspace$"] move scratchpad' ]
}

@test "added while the group is shown: it joins, and the group stays out" {
	GROUP=shown run "$SCRATCH" add
	[ "$status" -eq 0 ]
	grep -q 'move container to mark _scratch_workspace' "$CALLS"
	! grep -q 'scratchpad show\|move scratchpad' "$CALLS"
}

@test "toggle shows or hides the group; with none yet, the scratchpad as before" {
	GROUP=hidden run "$SCRATCH" toggle
	[ "$(cat "$CALLS")" = '[con_mark="^_scratch_workspace$"] scratchpad show' ]
	rm "$CALLS"
	GROUP=none run "$SCRATCH" toggle
	[ "$(cat "$CALLS")" = "scratchpad show" ]
}
