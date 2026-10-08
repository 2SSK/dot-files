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

libvirt_fakes() { # <state>: "broken" (nothing set up) or "ok" (everything in place)
	local bin="$BATS_TEST_TMPDIR/bin" ok=1
	[ "$1" = ok ] || ok=0
	# shellcheck disable=SC2016 # the fakes expand $* and friends when they run
	{
		printf '#!/bin/sh\necho "systemctl $*" >>"$CALLS"\n'
		printf 'case "$1" in is-enabled|is-active) [ "$2" = --quiet ] && [ "$3" = firewalld ] && exit 0; exit %s ;; esac\n' $((1 - ok))
	} >"$bin/systemctl"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "virsh $*" >>"$CALLS"\ncase "$*" in *net-info*) printf "Active:         %s\\nAutostart:      %s\\n" ;; esac\n' \
		"$( ((ok)) && echo yes || echo no)" "$( ((ok)) && echo yes || echo no)" >"$bin/virsh"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "firewall-cmd $*" >>"$CALLS"\ncase "$*" in *get-zone-of-interface*) echo %s ;; esac\n' \
		"$( ((ok)) && echo libvirt || echo 'no zone')" >"$bin/firewall-cmd"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "$USER wheel%s"\n' "$( ((ok)) && echo ' libvirt')" >"$bin/id"
	chmod +x "$bin"/*
}

@test "libvirt: enables the daemons, the default network, the firewall zone and the group" {
	libvirt_fakes broken
	run "$SYSTEM" libvirt
	[ "$status" -eq 0 ]
	grep -q 'systemctl enable --now virtqemud.socket' "$CALLS"
	grep -q 'systemctl enable --now virtnetworkd.socket' "$CALLS"
	grep -q 'virsh -c qemu:///system net-autostart default' "$CALLS"
	grep -q 'virsh -c qemu:///system net-start default' "$CALLS"
	grep -q 'firewall-cmd --quiet --permanent --zone=libvirt --add-interface=virbr0' "$CALLS"
	grep -q 'firewall-cmd --quiet --reload' "$CALLS"
	grep -q "usermod -aG libvirt $USER" "$CALLS"
}

@test "libvirt: changes nothing when everything is in place" {
	libvirt_fakes ok
	run "$SYSTEM" libvirt
	[ "$status" -eq 0 ]
	[[ $output == *"already in place"* ]]
	run grep -E 'enable --now|net-autostart|net-start|add-interface|usermod' "$CALLS"
	[ "$status" -eq 1 ]
}

@test "docker: enables the socket and adds the user to the docker group once" {
	printf '#!/bin/sh\necho "$USER wheel"\n' >"$BATS_TEST_TMPDIR/bin/id" # not in the docker group yet
	chmod +x "$BATS_TEST_TMPDIR/bin/id"
	run "$SYSTEM" docker
	[ "$status" -eq 0 ]
	grep -q 'systemctl enable --now docker.socket' "$CALLS"
	grep -q "usermod -aG docker $USER" "$CALLS"
}

grub_fakes() { # a palette, /etc/default/grub, and fake font/image/grub tools
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	mkdir -p "$XDG_STATE_HOME/desktop/theme" "$SYSTEM_ROOT/etc/default" "$SYSTEM_ROOT/boot/grub"
	echo '{"ui": {"bg": "#1a1b26", "fg": "#c0caf5", "fg_muted": "#737aa2", "surface": "#292e42"}}' \
		>"$XDG_STATE_HOME/desktop/theme/palette.json"
	printf 'GRUB_TIMEOUT=5\n#GRUB_THEME="/boot/grub/themes/starfield/theme.txt"\nGRUB_GFXMODE=auto' \
		>"$SYSTEM_ROOT/etc/default/grub" # no final newline, like a hand-edited file
	local bin="$BATS_TEST_TMPDIR/bin"
	printf '#!/bin/sh\necho "/fonts/Inter.ttc:0"\n' >"$bin/fc-match"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\nwhile [ $# -gt 1 ]; do [ "$1" = -o ] && out=$2; shift; done\nprintf "FILE\\0\\0\\0\\4PFF2NAME\\0\\0\\0\\23Desktop Regular 26\\0" >"$out"\n' >"$bin/grub-mkfont"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\nfor out; do :; done\nout=${out#PNG32:}\nfor i in 0 1 2 3 4 5 6 7 8; do echo "$i" >"$(printf "$out" "$i")"; done\n' >"$bin/magick"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "grub-mkconfig $*" >>"$CALLS"\n' >"$bin/grub-mkconfig"
	chmod +x "$bin"/*
}

@test "grub: installs the theme, points GRUB at it and regenerates the config once" {
	grub_fakes
	run "$SYSTEM" grub
	[ "$status" -eq 0 ]
	theme="$SYSTEM_ROOT/boot/grub/themes/desktop"
	grep -q 'desktop-color: "#1a1b26"' "$theme/theme.txt"
	grep -q 'item_font = "Desktop Regular 26"' "$theme/theme.txt"
	[ -f "$theme/select_nw.png" ] && [ -f "$theme/select_c.png" ] && [ -f "$theme/menu.pf2" ]
	grep -qx 'GRUB_THEME="/boot/grub/themes/desktop/theme.txt"' "$SYSTEM_ROOT/etc/default/grub"
	grep -qx 'GRUB_GFXMODE=auto' "$SYSTEM_ROOT/etc/default/grub"
	grep -qx 'GRUB_TERMINAL_OUTPUT="gfxterm"' "$SYSTEM_ROOT/etc/default/grub"
	grep -q "grub-mkconfig -o $SYSTEM_ROOT/boot/grub/grub.cfg" "$CALLS"
	rm "$CALLS"
	run "$SYSTEM" grub
	[[ $output == *"already in place"* ]]
	[ ! -e "$CALLS" ]
}

@test "grub: leaves a serial console alone" {
	grub_fakes
	printf '\nGRUB_TERMINAL="serial console"\n' >>"$SYSTEM_ROOT/etc/default/grub"
	run "$SYSTEM" grub
	[ "$status" -eq 0 ]
	[[ $output == *"event=grub_serial"* ]]
	run grep -q GRUB_TERMINAL_OUTPUT "$SYSTEM_ROOT/etc/default/grub"
	[ "$status" -eq 1 ]
}

@test "unknown part is a usage error" {
	run "$SYSTEM" bogus
	[ "$status" -eq 2 ]
}
