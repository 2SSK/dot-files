#!/usr/bin/env bats
# desktop-doctor against a throwaway $HOME and a fake session.

setup() {
	# never the real login screen or boot menu (system.sh shares their backgrounds and colours with us)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/no-sddm" DESKTOP_GRUB_DIR="$BATS_TEST_TMPDIR/no-grub"
	DOCTOR="$BATS_TEST_DIRNAME/../.local/bin/desktop-doctor"
	REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export HOME="$BATS_TEST_TMPDIR/home" NO_COLOR=1
	mkdir -p "$HOME"
	unset HYPRLAND_INSTANCE_SIGNATURE NIRI_SOCKET SWAYSOCK I3SOCK WAYLAND_DISPLAY DISPLAY DESKTOP_WM DESKTOP_DISPLAY
}

@test "--help exits 0" {
	run "$DOCTOR" --help
	[ "$status" -eq 0 ]
	[[ $output == *"usage:"* ]]
}

@test "unknown option is a usage error" {
	run "$DOCTOR" --bogus
	[ "$status" -eq 2 ]
}

@test "reports the detected session" {
	SWAYSOCK=/fake WAYLAND_DISPLAY=wayland-1 run "$DOCTOR"
	[[ $output == *"✓ session: sway on wayland"* ]]
}

@test "no session is a failure" {
	PATH="/usr/bin:/bin" run "$DOCTOR"
	[ "$status" -eq 1 ]
	[[ $output == *"✗ session"* ]]
}

@test "broken link into the repo fails, with a hint under --fix-hints" {
	ln -s "$REPO/gone.conf" "$HOME/gone.conf"
	SWAYSOCK=/fake WAYLAND_DISPLAY=wayland-1 run "$DOCTOR" --fix-hints
	[ "$status" -eq 1 ]
	[[ $output == *"✗ links: 1 broken"* ]]
	[[ $output == *"→ "*"setup.sh"* ]]
}
