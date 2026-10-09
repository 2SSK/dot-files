#!/usr/bin/env bats
# packages/install.sh: distro detection and list resolution (--dry-run only).

setup() {
	INSTALL="$BATS_TEST_DIRNAME/../packages/install.sh"
	export OS_RELEASE="$BATS_TEST_TMPDIR/os-release"
}

os() { printf '%s\n' "$@" >"$OS_RELEASE"; }

@test "arch: plain names go to pacman, aur: names to the AUR helper" {
	os ID=arch
	run "$INSTALL" --dry-run x11
	[ "$status" -eq 0 ]
	[[ ${lines[0]} == "native: i3-wm "* && $output == *" picom "* ]]
	[[ $output == *"aur: i3lock-color"* ]]
	[[ ${lines[2]} == "extra: st" ]] # built from source on every distro
}

@test "arch derivative via ID_LIKE resolves to the arch column" {
	os ID=endeavouros ID_LIKE=arch
	run "$INSTALL" --dry-run wayland
	[ "$status" -eq 0 ]
	[[ $output == *"extra: swayfx"* ]] # built against the repo scenefx
}

@test "ubuntu uses the debian column and dedupes repeated packages" {
	os ID=ubuntu 'ID_LIKE="debian"'
	run "$INSTALL" --dry-run x11
	[ "$status" -eq 0 ]
	[[ $output == *" picom "* ]]
	[ "$(grep -o x11-xserver-utils <<<"$output" | wc -l)" -eq 1 ]
	[[ $output == *"extra: i3lock-color"* ]]
}

@test "fedora uses the fedora column" {
	os ID=fedora
	run "$INSTALL" --dry-run x11
	[ "$status" -eq 0 ]
	[[ $output == "native: i3 "* && $output == *" picom "* ]]
	[[ $output == *"dex-autostart"* ]]
}

@test "default layers are base cli x11 wayland, not dev" {
	os ID=arch
	run "$INSTALL" --dry-run
	[ "$status" -eq 0 ]
	[[ $output == *"quickshell"* && $output == *"zsh"* && $output == *"swayfx"* ]]
	[[ $output != *"shellcheck"* ]]
}

@test "unsupported distro exits 3" {
	os ID=gentoo
	run "$INSTALL" --dry-run
	[ "$status" -eq 3 ]
	[[ $output == *"event=unsupported_distro"* ]]
}

@test "unknown layer is a usage error" {
	os ID=arch
	run "$INSTALL" --dry-run nope
	[ "$status" -eq 2 ]
}

@test "--help exits 0" {
	run "$INSTALL" --help
	[ "$status" -eq 0 ]
	[[ $output == *"usage:"* ]]
}

@test "--distro prints the detected distro" {
	os ID=ubuntu ID_LIKE=debian
	run "$INSTALL" --distro
	[ "$status" -eq 0 ]
	[ "$output" = debian ]
}
