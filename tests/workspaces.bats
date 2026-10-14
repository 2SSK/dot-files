#!/usr/bin/env bats
# Workspaces across screens, the same on i3 and sway (both read i3's workspaces.conf): 1-5 on the
# external monitor, 6-10 on the laptop panel, and everything on the panel when it's alone. Sway's
# outputs put the panel at the left and leave externals to sway, which adds them to its right.

setup() {
	REPO="$BATS_TEST_DIRNAME/.."
	WS="$REPO/.config/i3/conf.d/workspaces.conf"
	OUTPUTS="$REPO/.config/sway/outputs"
}

# the screens workspace $1 is assigned to, in order
screens() {
	sed -nE "s/^workspace $1 output (.*)$/\1/p" "$WS"
}

@test "workspaces 1-5 go to whichever external port is connected, else the panel" {
	local n
	for n in 1 2 3 4 5; do
		read -ra list <<<"$(screens "$n")"
		[ "${list[-1]}" = eDP-1 ] || { echo "workspace $n: ${list[*]}" && false; }
		# sway's and X11's names for HDMI and DisplayPort
		local port
		for port in HDMI-A-1 HDMI-1 HDMI-2 DP-1 DP-2 DP-3; do
			[[ " ${list[*]} " == *" $port "* ]] || { echo "workspace $n misses $port" && false; }
		done
	done
}

@test "workspaces 6-10 stay on the laptop panel" {
	local n
	for n in 6 7 8 9 10; do
		[ "$(screens "$n")" = eDP-1 ] || { echo "workspace $n: $(screens "$n")" && false; }
	done
}

@test "sway's outputs place the panel at the left and assign no workspaces of their own" {
	grep -qE '^output eDP-1 .*pos 0 0' "$OUTPUTS"
	run grep -nE '^workspace|^output (HDMI|DP)\S* .*pos' "$OUTPUTS"
	[ "$status" -eq 1 ]
}

@test "a whole workspace moves to the other screen" {
	grep -qx 'bindsym $mod+Ctrl+Left move workspace to output left' "$WS"
	grep -qx 'bindsym $mod+Ctrl+Right move workspace to output right' "$WS"
}
