#!/usr/bin/env bats
# packages/extra/swayfx.sh on Arch: sway is only swapped out once SwayFX has built, and comes back if
# the built package won't install. Fake pacman, makepkg, git and sudo record what they're asked.

setup() {
	SCRIPT="$BATS_TEST_DIRNAME/../packages/extra/swayfx.sh"
	export CALLS="$BATS_TEST_TMPDIR/calls"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	# shellcheck disable=SC2016 # expands when the fakes run
	printf '#!/bin/sh\n"$@"\n' >"$bin/sudo"
	# pacman: sway installed, swayfx not; -U fails when $INSTALL_FAILS
	# shellcheck disable=SC2016
	# $SWAYFX: unset, not installed; "repo", built against the repo's scenefx; "aur", against scenefx0.5
	printf '#!/bin/sh\necho "pacman $*" >>"$CALLS"\ncase "$*" in "-Qq sway") [ -z "$SWAYFX" ] ;; "-Qq swayfx") [ -n "$SWAYFX" ] ;;
	"-Qi swayfx") [ "$SWAYFX" = aur ] && echo "Depends On : cairo scenefx0.5 wlroots0.20" || echo "Depends On : cairo scenefx wlroots0.20" ;;
	"-Sw --noconfirm scenefx") [ -z "$DOWNLOAD_FAILS" ] ;; "-Sp scenefx") echo file:///var/cache/pacman/pkg/scenefx-0.5-1-x86_64.pkg.tar.zst ;;
	-U*) [ -z "$INSTALL_FAILS" ] ;; esac\n' >"$bin/pacman"
	# git clone: a recipe folder; makepkg: a built package there, unless $BUILD_FAILS
	# shellcheck disable=SC2016
	printf '#!/bin/sh\nfor last; do :; done\nmkdir -p "$last"\necho "depends=(\\"scenefx0.5\\")" >"$last/PKGBUILD"\n' >"$bin/git"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "makepkg $*" >>"$CALLS"\n[ -z "$BUILD_FAILS" ] || exit 1\ntouch swayfx-0.6-1-x86_64.pkg.tar.zst\n' >"$bin/makepkg"
	chmod +x "$bin"/*
	export PATH="$bin:/usr/bin:/bin"
}

@test "a failed build leaves sway installed" {
	BUILD_FAILS=1 run "$SCRIPT"
	[ "$status" -ne 0 ]
	! grep -q 'pacman -Rdd' "$CALLS"
}

@test "built first, then sway swapped for it" {
	run "$SCRIPT"
	[ "$status" -eq 0 ]
	grep -q '^makepkg -s --noconfirm' "$CALLS"
	[ "$(grep -n 'makepkg' "$CALLS" | cut -d: -f1)" -lt "$(grep -n 'pacman -Rdd --noconfirm sway' "$CALLS" | cut -d: -f1)" ]
	grep -q 'pacman -U --noconfirm .*swayfx-0.6-1-x86_64.pkg.tar.zst' "$CALLS"
	! grep -q 'pacman -S --noconfirm sway' "$CALLS"
}

@test "a package that won't install brings sway back" {
	INSTALL_FAILS=1 run "$SCRIPT"
	[ "$status" -ne 0 ]
	grep -q 'pacman -S --noconfirm sway$' "$CALLS"
}

@test "an up-to-date swayfx (built against the repo's scenefx) is left alone" {
	SWAYFX=repo run "$SCRIPT"
	[ "$status" -eq 0 ]
	! grep -q 'makepkg\|-Rdd\|-U ' "$CALLS"
}

@test "a swayfx built against the AUR's scenefx0.5: scenefx downloaded, swapped in, swayfx rebuilt" {
	SWAYFX=aur run "$SCRIPT"
	[ "$status" -eq 0 ]
	line() { grep -n -- "$1" "$CALLS" | head -1 | cut -d: -f1; }
	# downloaded before anything goes; the same library swapped in; then the rebuild against it
	[ "$(line '-Sw --noconfirm scenefx')" -lt "$(line '-Rdd --noconfirm scenefx0.5')" ]
	[ "$(line '-Rdd --noconfirm scenefx0.5')" -lt "$(line '-U --noconfirm /var/cache/pacman/pkg/scenefx-0.5-1')" ]
	[ "$(line '-U --noconfirm /var/cache/pacman/pkg/scenefx')" -lt "$(line '^makepkg')" ]
	grep -q 'pacman -U --noconfirm .*swayfx-0.6-1-x86_64.pkg.tar.zst' "$CALLS"
	! grep -q 'pacman -Rdd --noconfirm sway$' "$CALLS" # no sway to swap out: swayfx is the compositor
}

@test "scenefx won't download: scenefx0.5 stays, swayfx as it was" {
	SWAYFX=aur DOWNLOAD_FAILS=1 run "$SCRIPT"
	[ "$status" -ne 0 ]
	! grep -q 'scenefx0.5' "$CALLS"
	! grep -q 'makepkg' "$CALLS"
}
