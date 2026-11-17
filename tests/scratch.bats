#!/usr/bin/env bats
# desktop scratch, the scratchpad as one floating workspace, with a fake swaymsg: $GROUP is none,
# hidden or shown; it records the commands it's given.

setup() {
	SCRATCH="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/scratch"
	export CALLS="$BATS_TEST_TMPDIR/calls" SWAYSOCK=fake
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '%s\n' '#!/bin/sh' 'case "$1 $2" in' \
		'"-t get_marks") [ "$GROUP" = none ] && echo "[]" || echo "[\"_scratch_workspace\"]" ;;' \
		'"-t get_tree") case "$GROUP" in' \
		'  hidden) echo "{\"name\":\"__i3_scratch\",\"floating_nodes\":[{\"type\":\"floating_con\",\"marks\":[\"_scratch_workspace\"]}]}" ;;' \
		'  inside) echo "{\"nodes\":[{\"type\":\"floating_con\",\"marks\":[\"_scratch_workspace\"],\"nodes\":[{\"type\":\"con\",\"focused\":true}]}]}" ;;' \
		'  tiled) echo "{\"nodes\":[{\"type\":\"con\",\"marks\":[\"_scratch_workspace\"],\"nodes\":[{\"type\":\"con\",\"id\":7}]}]}" ;;' \
		'  *) echo "{\"nodes\":[{\"type\":\"floating_con\",\"marks\":[\"_scratch_workspace\"]}]}" ;; esac ;;' \
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

@test "pressed on a window already in the group: the group goes away, as the scratchpad key did" {
	GROUP=inside run "$SCRATCH" add
	[ "$status" -eq 0 ]
	[ "$(cat "$CALLS")" = '[con_mark="^_scratch_workspace$"] move scratchpad' ]
}

@test "a group that ended up tiled is floated again (tabbed, centred) before anything else" {
	GROUP=tiled run "$SCRATCH" toggle
	[ "$status" -eq 0 ]
	grep -q '\[con_mark="^_scratch_workspace\$"\] floating enable' "$CALLS"
	grep -q '\[con_id=7\] layout tabbed' "$CALLS"
	[ "$(grep -n 'floating enable' "$CALLS" | cut -d: -f1)" -lt "$(grep -n 'scratchpad show' "$CALLS" | cut -d: -f1)" ]
}

# i3: the same commands through i3-msg, with i3's tree (the group is the container inside the
# floating one, floating "user_on")
i3_fake() {
	unset SWAYSOCK
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '%s\n' '#!/bin/sh' 'case "$1 $2" in' \
		'"-t get_marks") [ "$GROUP" = none ] && echo "[]" || echo "[\"_scratch_workspace\"]" ;;' \
		'"-t get_tree") case "$GROUP" in' \
		'  none) echo "{\"nodes\":[{\"type\":\"con\",\"id\":42,\"nodes\":[{\"type\":\"con\",\"marks\":[\"_scratch_incoming\"]}]}]}" ;;' \
		'  hidden) echo "{\"name\":\"__i3_scratch\",\"floating_nodes\":[{\"type\":\"floating_con\",\"nodes\":[{\"type\":\"con\",\"floating\":\"user_on\",\"marks\":[\"_scratch_workspace\"]}]}]}" ;;' \
		'  *) echo "{\"nodes\":[{\"type\":\"floating_con\",\"nodes\":[{\"type\":\"con\",\"floating\":\"user_on\",\"marks\":[\"_scratch_workspace\"]}]}]}" ;; esac ;;' \
		'*) shift; echo "$*" >>"$CALLS" ;;' 'esac' >"$bin/i3-msg"
	chmod +x "$bin/i3-msg"
}

@test "i3: the first window is wrapped beside a placeholder, then the wrapper floats as the group" {
	i3_fake
	GROUP=none run "$SCRATCH" add
	[ "$status" -eq 0 ]
	[ "$(sed -n 2p "$CALLS")" = "open; mark --add _scratch_placeholder" ]
	grep -qx '\[con_mark="^_scratch_incoming$"\] split v' "$CALLS"
	grep -qx '\[con_mark="^_scratch_placeholder$"\] kill' "$CALLS"
	grep -qx '\[con_id=42\] mark --add _scratch_workspace' "$CALLS"
	! grep -q 'focus parent' "$CALLS"
	[ "$(tail -1 "$CALLS")" = '[con_mark="^_scratch_workspace$"] resize set width 80 ppt height 75 ppt; [con_mark="^_scratch_workspace$"] move position center; [con_mark="^_scratch_workspace$"] move scratchpad' ]
}

@test "i3: a window joins while the group is tiled for a moment, and the group hides again" {
	i3_fake
	GROUP=hidden run "$SCRATCH" add
	[ "$status" -eq 0 ]
	[ "$(sed -n 3p "$CALLS")" = '[con_mark="^_scratch_workspace$"] floating disable' ]
	grep -q 'move container to mark _scratch_workspace' "$CALLS"
	[ "$(tail -1 "$CALLS")" = '[con_mark="^_scratch_workspace$"] move scratchpad' ]
}

@test "i3: toggle only shows or hides a floating group (it isn't healed)" {
	i3_fake
	GROUP=shown run "$SCRATCH" toggle
	[ "$status" -eq 0 ]
	[ "$(cat "$CALLS")" = '[con_mark="^_scratch_workspace$"] scratchpad show' ]
}
