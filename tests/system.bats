#!/usr/bin/env bats
# packages/system.sh against a throwaway root, with fake sudo/systemctl/virsh/usermod/sysctl.

setup() {
	SYSTEM="$BATS_TEST_DIRNAME/../packages/system.sh"
	export SYSTEM_ROOT="$BATS_TEST_TMPDIR/root" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$SYSTEM_ROOT" "$BATS_TEST_TMPDIR/bin"
	# sudo runs the command; the others only record what they were asked to do
	printf '#!/bin/sh\n"$@"\n' >"$BATS_TEST_TMPDIR/bin/sudo"
	for tool in systemctl virsh usermod sysctl; do
		# shellcheck disable=SC2016 # $* and $CALLS expand when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$BATS_TEST_TMPDIR/bin/$tool"
	done
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "memory: installs the zram and oomd config and enables oomd" {
	run "$SYSTEM" memory
	[ "$status" -eq 0 ]
	grep -q '^zram-size = min(ram / 2, 8192)$' "$SYSTEM_ROOT/etc/systemd/zram-generator.conf"
	grep -q '^ManagedOOMMemoryPressure=kill$' "$SYSTEM_ROOT/etc/systemd/system/user@.service.d/10-oomd.conf"
	grep -q '^vm.swappiness = 180$' "$SYSTEM_ROOT/etc/sysctl.d/99-zram.conf"
	grep -q 'systemctl enable --now systemd-oomd.service' "$CALLS"
}

@test "memory: a second run changes nothing" {
	"$SYSTEM" memory
	rm "$CALLS"
	run "$SYSTEM" memory
	[ "$status" -eq 0 ]
	[[ $output == *"already in place"* ]]
	[ ! -e "$CALLS" ]
}

@test "libvirt: enables the per-driver daemons when present, else libvirtd" {
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "systemctl $*" >>"$CALLS"\n[ "$1" != list-unit-files ]\n' >"$BATS_TEST_TMPDIR/bin/systemctl"
	run "$SYSTEM" libvirt
	[ "$status" -eq 0 ]
	grep -q 'systemctl enable --now libvirtd.socket' "$CALLS"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "systemctl $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/systemctl"
	rm "$CALLS"
	run "$SYSTEM" libvirt
	grep -q 'systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket' "$CALLS"
	grep -q 'virsh -c qemu:///system net-autostart default' "$CALLS"
}

@test "unknown part is a usage error" {
	run "$SYSTEM" bogus
	[ "$status" -eq 2 ]
}
