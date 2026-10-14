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

@test "Debian, Ubuntu and Mint are refused: Arch and Fedora only" {
	local release
	for release in 'ID=debian' $'ID=ubuntu\nID_LIKE=debian' $'ID=linuxmint\nID_LIKE="ubuntu debian"'; do
		printf '%s\n' "$release" >"$OS_RELEASE"
		run "$INSTALL" --dry-run
		[ "$status" -eq 3 ]
		[[ $output == *"Arch"*"Fedora"* ]]
	done
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
	os ID=nobara ID_LIKE=fedora
	run "$INSTALL" --distro
	[ "$status" -eq 0 ]
	[ "$output" = fedora ]
}

# --check: can this system run the desktop? The shell needs Qt 6.9 or newer, so on Fedora the Qt
# dnf offers decides. Fakes answer for apt-cache and dnf.
check_fakes() { # <os-release lines> <qt version offered, or "none">
	printf '%s\n' "$1" >"$BATS_TEST_TMPDIR/os-release"
	export OS_RELEASE="$BATS_TEST_TMPDIR/os-release"
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\n[ "%s" = none ] && v="(none)" || v="%s+dfsg-1"\nprintf "qt6-base-dev:\\n  Installed: (none)\\n  Candidate: %%s\\n" "$v"\n' "$2" "$2" >"$BATS_TEST_TMPDIR/bin/apt-cache"
	printf '#!/bin/sh\n[ "%s" = none ] || echo "%s"\n' "$2" "$2" >"$BATS_TEST_TMPDIR/bin/dnf"
	printf '#!/bin/sh\nexit 0\n' >"$BATS_TEST_TMPDIR/bin/sudo"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "--check: Arch passes" {
	check_fakes 'ID=arch' none
	run "$INSTALL" --check
	[ "$status" -eq 0 ]
}

@test "--check: Fedora with Qt 6.9+ passes, an older one is refused" {
	check_fakes $'ID=fedora\nVERSION_ID=44' 6.9.1
	run "$INSTALL" --check
	[ "$status" -eq 0 ]
	check_fakes $'ID=fedora\nVERSION_ID=42' 6.8.3
	run "$INSTALL" --check
	[ "$status" -eq 4 ]
	[[ $output == *"Qt 6.8"* && $output == *"6.9"* ]]
}
