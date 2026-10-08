#!/usr/bin/env bats
# desktop-vm with fake virsh/virt-install/curl/ssh that record what they were asked to do.

setup() {
	VM="$BATS_TEST_DIRNAME/../.local/bin/desktop-vm"
	export HOME="$BATS_TEST_TMPDIR/home" CALLS="$BATS_TEST_TMPDIR/calls" DESKTOP_VM_WAIT=0
	export DESKTOP_VM_MEMINFO="$BATS_TEST_TMPDIR/meminfo" XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
	mkdir -p "$HOME/.ssh" "$HOME/Dotfiles" "$BATS_TEST_TMPDIR/bin"
	echo 'ssh-ed25519 AAAAtestkey me@laptop' >"$HOME/.ssh/id_ed25519.pub"
	echo 'MemAvailable:   12582912 kB' >"$DESKTOP_VM_MEMINFO" # 12 GiB free
	bin="$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # the fakes expand $* and friends when they run
	{
		printf '#!/bin/sh\necho "virsh $*" >>"$CALLS"\ncase "$*" in\n'
		printf '*dominfo*) [ -n "$VM_EXISTS" ] ;;\n'
		printf '*pool-dumpxml*) echo "  <path>/pool</path>" ;;\n'
		printf '*vol-info*) exit 1 ;;\n'
		printf '*domifaddr*) printf " vnet0  52:54:00:aa:bb:cc  ipv4  192.168.122.50/24\\n" ;;\n'
		printf 'esac\n'
	} >"$bin/virsh"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "virt-install $*" >>"$CALLS"\nfor a; do case $a in user-data=*) cp "${a#user-data=}" "$CALLS.user-data" ;; esac; done\n' >"$bin/virt-install"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "curl $*" >>"$CALLS"\nwhile [ $# -gt 0 ]; do [ "$1" = -o ] && echo image >"$2"; shift; done\n' >"$bin/curl"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "ssh $*" >>"$CALLS"\n' >"$bin/ssh"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
}

calls() { cat "$CALLS"; }

@test "server VM: cloud image, no display, user and key from cloud-init" {
	run "$VM" create web --image debian --cpus 2 --mem 2G --disk 20G
	[ "$status" -eq 0 ]
	[[ $(calls) == *"curl "*"debian-13-genericcloud-amd64.qcow2"* ]]
	[[ $(calls) == *"virsh -q -c qemu:///system vol-upload --pool default desktop-vm-base-debian-13-genericcloud-amd64.qcow2"* ]]
	local vi; vi="$(grep '^virt-install' "$CALLS")"
	[[ $vi == *"--name web"* && $vi == *"--memory 2048"* && $vi == *"--vcpus 2"* ]]
	[[ $vi == *"--osinfo debian13"* && $vi == *"--import"* && $vi == *"--graphics none"* ]]
	[[ $vi == *"size=20,backing_store=/pool/desktop-vm-base-debian-13-genericcloud-amd64.qcow2"* ]]
	grep -q "name: $USER" "$CALLS.user-data"
	grep -q 'ssh-ed25519 AAAAtestkey me@laptop' "$CALLS.user-data"
	grep -q 'qemu-guest-agent' "$CALLS.user-data"
}

@test "GUI VM with a read-only shared folder" {
	run "$VM" create rice --image arch --gui --share "$HOME/Dotfiles:dotfiles:ro"
	[ "$status" -eq 0 ]
	local vi; vi="$(grep '^virt-install' "$CALLS")"
	[[ $vi == *"--graphics spice"* && $vi == *"--video virtio"* && $vi == *"--osinfo archlinux"* ]]
	[[ $vi == *"--memorybacking source.type=memfd,access.mode=shared"* ]]
	[[ $vi == *"--filesystem source.dir=$HOME/Dotfiles,target.dir=dotfiles,driver.type=virtiofs,readonly=on"* ]]
	grep -q 'spice-vdagent' "$CALLS.user-data"
	grep -q "dotfiles, /home/$USER/dotfiles, virtiofs" "$CALLS.user-data"
}

@test "an installer ISO gets a display and no cloud-init" {
	touch "$HOME/os.iso"
	run "$VM" create try --iso "$HOME/os.iso" --disk 30G
	[ "$status" -eq 0 ]
	local vi; vi="$(grep '^virt-install' "$CALLS")"
	[[ $vi == *"--cdrom $HOME/os.iso"* && $vi == *"--graphics spice"* && $vi == *"size=30"* ]]
	[[ $vi != *"--cloud-init"* && $vi != *"--import"* ]]
}

@test "refuses to start a VM that would leave the laptop under 2 GiB" {
	echo 'MemAvailable:   3145728 kB' >"$DESKTOP_VM_MEMINFO" # 3 GiB free
	run "$VM" create big --image ubuntu --mem 2G
	[ "$status" -eq 1 ]
	[[ $output == *"event=low_memory"* ]]
	run grep -q '^virt-install' "$CALLS"
	[ "$status" -eq 1 ]
}

@test "needs an SSH key to preconfigure access" {
	rm "$HOME/.ssh/id_ed25519.pub"
	run "$VM" create web --image debian
	[ "$status" -eq 1 ]
	[[ $output == *"event=no_ssh_key"* ]]
}

@test "unknown image name is a usage error" {
	run "$VM" create web --image beos
	[ "$status" -eq 2 ]
}

@test "ip and ssh find the VM through its DHCP lease" {
	VM_EXISTS=1 run "$VM" ip web
	[ "$output" = 192.168.122.50 ]
	VM_EXISTS=1 run "$VM" ssh web uptime
	[[ $(calls) == *"ssh "*"$USER@192.168.122.50 uptime"* ]]
}

@test "delete removes the VM and its disk" {
	VM_EXISTS=1 run "$VM" delete web -y
	[ "$status" -eq 0 ]
	[[ $(calls) == *"virsh -q -c qemu:///system undefine web --remove-all-storage"* ]]
}
