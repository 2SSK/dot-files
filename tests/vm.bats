#!/usr/bin/env bats
# vm with fake virsh/virt-install/curl/virt-manager/osinfo-query that record their calls.

setup() {
	VM="$BATS_TEST_DIRNAME/../.local/bin/vm"
	export HOME="$BATS_TEST_TMPDIR/home" CALLS="$BATS_TEST_TMPDIR/calls" USER=tester VM_PASSWORD=secret
	export VM_MEMINFO="$BATS_TEST_TMPDIR/meminfo" XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
	mkdir -p "$HOME/dev/dot-files-rewrite" "$HOME/notes" "$BATS_TEST_TMPDIR/bin"
	echo 'MemAvailable:   12582912 kB' >"$VM_MEMINFO" # 12 GiB free
	bin="$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # the fakes expand $* and friends when they run
	{
		printf '#!/bin/sh\necho "virsh $*" >>"$CALLS"\ncase "$*" in\n'
		printf '*dominfo*) [ -n "$VM_EXISTS" ] || grep -q -- "^virt-install .*--name $5 " "$CALLS" && echo "Max memory:     2097152 KiB" || exit 1 ;;\n'
		printf '*domstate*) echo "${VM_STATE:-shut off}" ;;\n'
		printf '*pool-dumpxml*) echo "  <path>/pool</path>" ;;\n'
		printf '*dumpxml*) echo "<graphics type=${VM_GRAPHICS:-'"'"'spice'"'"'}>" ;;\n'
		printf '*vol-info*) exit 1 ;;\n'
		printf 'esac\n'
	} >"$bin/virsh"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "virt-install $*" >>"$CALLS"\nfor a; do case $a in user-data=*) cp "${a#user-data=}" "$CALLS.user-data" ;; esac; done\n' >"$bin/virt-install"
	# shellcheck disable=SC2016 # with -o the fake "downloads"; without it, it serves a directory listing
	printf '#!/bin/sh\necho "curl $*" >>"$CALLS"\nout=\nwhile [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done\n[ -n "$out" ] && echo image >"$out" || echo "<a href=\\"Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2\\">"\n' >"$bin/curl"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "virt-manager $*" >>"$CALLS"\n' >"$bin/virt-manager"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho " ${2#short-id=} | name"\n' >"$bin/osinfo-query"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
}

calls() { cat "$CALLS"; }
vi_args() { grep '^virt-install' "$CALLS"; }

@test "create defaults: arch, 2 CPUs, 4 GiB, 30 GiB thin disk, serial console" {
	run "$VM" create box
	[ "$status" -eq 0 ]
	[[ $(calls) == *"curl "*"/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"* ]]
	[[ $(vi_args) == *"--connect qemu:///system --name box --memory 4096 --vcpus 2 --osinfo archlinux --import"* ]]
	[[ $(vi_args) == *"--channel unix,target.type=virtio,target.name=org.qemu.guest_agent.0"* ]]
	[[ $(vi_args) == *"size=30,backing_store=/pool/vm-base-Arch-Linux-x86_64-cloudimg.qcow2"* ]]
	[[ $(vi_args) == *"--graphics none"* && $(vi_args) != *"--filesystem"* ]]
	grep -q 'name: tester' "$CALLS.user-data"
	grep -qE 'passwd: "[$]6[$]' "$CALLS.user-data"
	run grep -q secret "$CALLS.user-data" # only the hash reaches the VM
	[ "$status" -eq 1 ]
}

@test "other distros and versions" {
	run "$VM" create a --image debian:12
	[[ $(calls) == *"/bookworm/latest/debian-12-generic-amd64.qcow2"* && $(vi_args) == *"--osinfo debian12"* ]]
	run "$VM" create b --image ubuntu
	[[ $(calls) == *"/releases/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img"* ]]
	run "$VM" create c --image fedora:43
	[[ $(calls) == *"releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"* ]]
	run "$VM" create d --image debian:9
	[ "$status" -eq 1 ]
	[[ $output == *"event=unknown_version"* ]]
}

@test "shares: read-only by default, own tag, :rw, mounted in the home" {
	# shellcheck disable=SC2088 # vm expands ~ itself
	run "$VM" create rice --share "~/dev/dot-files-rewrite:dot-files" --share "$HOME/notes::rw"
	[ "$status" -eq 0 ]
	[[ $(vi_args) == *"--filesystem source.dir=$HOME/dev/dot-files-rewrite,target.dir=dot-files,driver.type=virtiofs,readonly=on"* ]]
	[[ $(vi_args) == *"--filesystem source.dir=$HOME/notes,target.dir=notes,driver.type=virtiofs --"* ]]
	[[ $(vi_args) == *"--memorybacking source.type=memfd,access.mode=shared"* ]]
	grep -q 'dot-files /home/tester/dot-files virtiofs defaults,nofail' "$CALLS.user-data"
	grep -q 'notes /home/tester/notes virtiofs defaults,nofail' "$CALLS.user-data"
	run grep -q '^mounts:' "$CALLS.user-data" # would run before the user exists
	[ "$status" -eq 1 ]
	run "$VM" create x --share "$HOME/missing"
	[ "$status" -eq 1 ]
	[[ $output == *"event=no_share_dir"* ]]
}

@test "--desktop: display, i3 + sway + sddm (quickshell on arch), window opens" {
	run "$VM" create rice --desktop --pkgs "git stow"
	[ "$status" -eq 0 ]
	[[ $(vi_args) == *"--graphics spice"* && $(vi_args) == *"--channel spicevmc"* ]]
	grep -q 'packages: \[qemu-guest-agent, git, stow, i3-wm, sway, sddm, kitty, foot, quickshell, spice-vdagent\]' "$CALLS.user-data"
	grep -q 'enable, --now, sddm' "$CALLS.user-data"
	grep -q 'Session=/usr/share/xsessions/i3.desktop' "$CALLS.user-data" # i3 preselected
	[[ $(calls) == *"virt-manager --connect qemu:///system --show-domain-console rice"* ]]
	run "$VM" create deb --image debian --desktop
	grep -q 'packages: \[qemu-guest-agent, i3, sway, sddm, kitty, foot, spice-vdagent\]' "$CALLS.user-data"
}

@test "--desktop is unsupported on an unknown image" {
	touch "$HOME/my.qcow2"
	run "$VM" create x --image "$HOME/my.qcow2" --desktop
	[ "$status" -eq 3 ]
}

@test "refuses a VM that would leave the laptop under 2 GiB, unless forced" {
	run "$VM" create big --mem 11G
	[ "$status" -eq 1 ]
	[[ $output == *"event=low_memory"* ]]
	run grep -q '^virt-install' "$CALLS"
	[ "$status" -eq 1 ]
	run "$VM" create big --mem 11G --force
	[ "$status" -eq 0 ]
}

@test "bad usage exits 2; an existing name is refused" {
	run "$VM" create box --nope
	[ "$status" -eq 2 ]
	run "$VM" create box --cpus
	[ "$status" -eq 1 ]
	VM_EXISTS=1 run "$VM" create box
	[ "$status" -eq 1 ]
	[[ $output == *"event=vm_exists"* ]]
}

@test "start, stop, snap, revert, rm" {
	export VM_EXISTS=1
	run "$VM" start box
	[[ $(calls) == *"virsh -q -c qemu:///system start box"* && $(calls) == *"--show-domain-console box"* ]]
	run "$VM" stop box
	[[ $(calls) == *"shutdown box"* ]]
	run "$VM" stop box --force
	[[ $(calls) == *"destroy box"* ]]
	run "$VM" snap box clean
	[[ $(calls) == *"snapshot-create-as box clean"* ]]
	run "$VM" revert box clean
	[[ $(calls) == *"snapshot-revert box clean"* ]]
	run "$VM" rm box -y
	[[ $(calls) == *"undefine box --remove-all-storage --snapshots-metadata"* ]]
}

@test "console logs in on the serial console" {
	VM_EXISTS=1 run "$VM" console box
	[ "$status" -eq 0 ]
	[[ $(calls) == *"virsh -c qemu:///system console box"* ]]
}

@test "snap refuses a running VM" {
	VM_EXISTS=1 VM_STATE=running run "$VM" snap box
	[ "$status" -eq 1 ]
	[[ $output == *"event=vm_running"* ]]
}

@test "a missing VM is an error" {
	run "$VM" start nope
	[ "$status" -eq 1 ]
	[[ $output == *"event=no_vm"* ]]
}

@test "list: name, state, and the IP while running" {
	# shellcheck disable=SC2016
	printf '#!/bin/sh\ncase "$*" in *"list --all --name"*) printf "rice\\nsrv\\n" ;; *"domstate rice"*) echo running ;; *domstate*) echo "shut off" ;; *domifaddr*) printf " vnet0  52:54:00:aa:bb:cc  ipv4  192.168.122.50/24\\n" ;; esac\n' >"$BATS_TEST_TMPDIR/bin/virsh"
	run "$VM" list
	[ "$status" -eq 0 ]
	[[ ${lines[0]} == "rice "*"running "*"192.168.122.50" ]]
	[[ ${lines[1]} == "srv "*"shut off"* ]]
}

@test "snaps lists snapshot names" {
	VM_EXISTS=1 run "$VM" snaps box
	[[ $(calls) == *"snapshot-list box --name"* ]]
}

@test "help: short by default, details per command" {
	run "$VM"
	[ "$status" -eq 0 ]
	[[ $output == *"vm guide"* && $output != *"--image"* ]]
	[ "${#lines[@]}" -lt 20 ]
	run "$VM" help create
	[[ $output == *"--share <dir>[:tag][:rw]"* ]]
	run "$VM" help stop
	[[ $output == *"--force cuts the power"* ]]
}

@test "an unknown command is a usage error, not virsh" {
	run "$VM" snapshot-list box
	[ "$status" -eq 2 ]
	[[ $output == *"event=unknown_command"* && $output == *"vm console <name>"* ]]
	[ ! -e "$CALLS" ] # virsh never ran
}
