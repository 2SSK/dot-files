#!/usr/bin/env bats
# .local/lib/desktop/bin/shell: which EGL driver the shell gets. A fake qs prints what it was given; fake
# sysfs cards say which GPU the screen hangs off.

setup() {
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "egl=$__EGL_VENDOR_LIBRARY_FILENAMES"\n' >"$bin/qs" && chmod +x "$bin/qs"
	export PATH="$bin:$PATH" DESKTOP_DRM_DIR="$BATS_TEST_TMPDIR/drm" DESKTOP_EGL_DIR="$BATS_TEST_TMPDIR/egl"
	mkdir -p "$DESKTOP_EGL_DIR" && touch "$DESKTOP_EGL_DIR/50_mesa.json"
	unset __EGL_VENDOR_LIBRARY_FILENAMES
}

card() { # card <n> <driver> <boot_vga>
	mkdir -p "$DESKTOP_DRM_DIR/card$1/device" "$BATS_TEST_TMPDIR/drivers/$2"
	ln -sfn "$BATS_TEST_TMPDIR/drivers/$2" "$DESKTOP_DRM_DIR/card$1/device/driver"
	echo "$3" >"$DESKTOP_DRM_DIR/card$1/device/boot_vga"
}

@test "screen on Intel, NVIDIA beside it: Mesa only" {
	card 1 nvidia 0 && card 2 i915 1
	run "$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/shell"
	[ "$output" = "egl=$DESKTOP_EGL_DIR/50_mesa.json" ]
}

@test "screen on NVIDIA: left to glvnd" {
	card 0 nvidia 1
	run "$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/shell"
	[ "$output" = "egl=" ]
}

@test "no Mesa installed: left to glvnd" {
	card 0 amdgpu 1 && rm "$DESKTOP_EGL_DIR/50_mesa.json"
	run "$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/shell"
	[ "$output" = "egl=" ]
}
