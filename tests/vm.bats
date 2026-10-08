#!/usr/bin/env bats
# vm with a JSON config and fake virsh/virt-install/curl/ssh/osinfo-query that record their calls.

setup() {
	VM="$BATS_TEST_DIRNAME/../.local/bin/vm"
	export HOME="$BATS_TEST_TMPDIR/home" CALLS="$BATS_TEST_TMPDIR/calls" VM_WAIT=0
	export VM_MEMINFO="$BATS_TEST_TMPDIR/meminfo" XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
	export VM_CONFIG="$BATS_TEST_TMPDIR/vms.json"
	mkdir -p "$HOME/.ssh" "$HOME/Dotfiles" "$BATS_TEST_TMPDIR/bin"
	echo 'ssh-ed25519 AAAAtestkey me@laptop' >"$HOME/.ssh/id_ed25519.pub"
	echo 'MemAvailable:   12582912 kB' >"$VM_MEMINFO" # 12 GiB free
	cat >"$VM_CONFIG" <<-'EOF'
		{
		  "defaults": { "image": "ubuntu:26.04", "cpus": 2, "memory": "2G", "disk": "20G", "gui": false,
		                "user": null, "password": null, "ssh_keys": ["~/.ssh/*.pub"] },
		  "vms": {
		    "web":   { "image": "debian:12", "cpus": 4, "memory": "3G" },
		    "box":   { },
		    "fed":   { "image": "fedora:43" },
		    "rice":  { "image": "arch", "gui": true, "memory": "4G", "disk": "30G", "user": "tester",
		               "password": "secret", "shares": [{ "source": "~/Dotfiles", "tag": "dotfiles", "readonly": true }] },
		    "try":   { "iso": "~/os.iso", "disk": "30G" },
		    "big":   { "memory": "11G" },
		    "nokey": { "ssh_keys": [] }
		  }
		}
	EOF
	bin="$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # the fakes expand $* and friends when they run
	{
		printf '#!/bin/sh\necho "virsh $*" >>"$CALLS"\ncase "$*" in\n'
		printf '*dominfo*) [ -n "$VM_EXISTS" ] && echo "Max memory:     2097152 KiB" ;;\n'
		printf '*domstate*) echo "${VM_STATE:-shut off}" ;;\n'
		printf '*pool-dumpxml*) echo "  <path>/pool</path>" ;;\n'
		printf '*vol-info*) exit 1 ;;\n'
		printf '*domifaddr*) printf " vnet0  52:54:00:aa:bb:cc  ipv4  192.168.122.50/24\\n" ;;\n'
		printf 'esac\n'
	} >"$bin/virsh"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "virt-install $*" >>"$CALLS"\nfor a; do case $a in user-data=*) cp "${a#user-data=}" "$CALLS.user-data" ;; esac; done\n' >"$bin/virt-install"
	# shellcheck disable=SC2016 # with -o the fake "downloads"; without it, it serves a directory listing
	printf '#!/bin/sh\necho "curl $*" >>"$CALLS"\nout=\nwhile [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done\n[ -n "$out" ] && echo image >"$out" || echo "<a href=\\"Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2\\">"\n' >"$bin/curl"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "ssh $*" >>"$CALLS"\n' >"$bin/ssh"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho " ${2#short-id=} | name"\n' >"$bin/osinfo-query"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
}

calls() { cat "$CALLS"; }
vi_args() { grep '^virt-install' "$CALLS"; }

@test "up creates a server VM from the config: image version, size, user and key" {
	run "$VM" up web
	[ "$status" -eq 0 ]
	[[ $(calls) == *"curl "*"/bookworm/latest/debian-12-genericcloud-amd64.qcow2"* ]]
	[[ $(vi_args) == *"--name web"* && $(vi_args) == *"--memory 3072"* && $(vi_args) == *"--vcpus 4"* ]]
	[[ $(vi_args) == *"--osinfo debian12"* && $(vi_args) == *"--graphics none"* && $(vi_args) == *"size=20,backing_store=/pool/"* ]]
	grep -q "name: $USER" "$CALLS.user-data"
	grep -q 'ssh-ed25519 AAAAtestkey me@laptop' "$CALLS.user-data"
}

@test "defaults fill in everything a VM doesn't set" {
	run "$VM" up box
	[ "$status" -eq 0 ]
	[[ $(calls) == *"/releases/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img"* ]]
	[[ $(vi_args) == *"--memory 2048"* && $(vi_args) == *"--vcpus 2"* && $(vi_args) == *"--osinfo ubuntu26.04"* ]]
}

@test "fedora finds the image of the requested release" {
	run "$VM" up fed
	[ "$status" -eq 0 ]
	[[ $(calls) == *"releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"* ]]
}

@test "GUI VM with custom credentials and a read-only share" {
	run "$VM" up rice
	[ "$status" -eq 0 ]
	[[ $(vi_args) == *"--graphics spice"* && $(vi_args) == *"--osinfo archlinux"* ]]
	[[ $(vi_args) == *"--filesystem source.dir=$HOME/Dotfiles,target.dir=dotfiles,driver.type=virtiofs,readonly=on"* ]]
	grep -q 'name: tester' "$CALLS.user-data"
	grep -qE 'passwd: "[$]6[$]' "$CALLS.user-data"
	run grep -q secret "$CALLS.user-data"
	[ "$status" -eq 1 ]
	grep -q 'dotfiles, /home/tester/dotfiles, virtiofs' "$CALLS.user-data"
	grep -q '/etc/udev/rules.d/50-x-resize.rules' "$CALLS.user-data" # the display follows the window
}

@test "an installer ISO gets a display and no cloud-init" {
	touch "$HOME/os.iso"
	run "$VM" up try
	[ "$status" -eq 0 ]
	[[ $(vi_args) == *"--cdrom $HOME/os.iso"* && $(vi_args) == *"size=30"* && $(vi_args) != *"--cloud-init"* ]]
}

@test "refuses a VM that would leave the laptop under 2 GiB" {
	run "$VM" up big
	[ "$status" -eq 1 ]
	[[ $output == *"event=low_memory"* ]]
	run grep -q '^virt-install' "$CALLS"
	[ "$status" -eq 1 ]
}

@test "needs a key or a password to log in" {
	run "$VM" up nokey
	[ "$status" -eq 1 ]
	[[ $output == *"event=no_credentials"* ]]
}

@test "a name missing from the config is an error" {
	run "$VM" up nope
	[ "$status" -eq 1 ]
	[[ $output == *"event=not_in_config"* ]]
}

@test "up starts an existing VM instead of creating it" {
	VM_EXISTS=1 run "$VM" up web
	[ "$status" -eq 0 ]
	[[ $(calls) == *"virsh -q -c qemu:///system start web"* ]]
	[[ $(calls) != *"virt-install"* ]]
}

@test "ssh, ip and rm" {
	VM_EXISTS=1 run "$VM" ip web
	[ "$output" = 192.168.122.50 ]
	VM_EXISTS=1 run "$VM" ssh web uptime
	[[ $(calls) == *"ssh "*"$USER@192.168.122.50 uptime"* ]]
	VM_EXISTS=1 run "$VM" rm web -y
	[[ $(calls) == *"virsh -q -c qemu:///system undefine web --remove-all-storage"* ]]
}

@test "ssh logs in as the VM's configured user" {
	VM_EXISTS=1 run "$VM" ssh rice
	[[ $(calls) == *"ssh "*"tester@192.168.122.50"* ]]
}

@test "tunnel forwards a VM port to the laptop" {
	VM_EXISTS=1 run "$VM" tunnel web 5432
	[ "$status" -eq 0 ]
	[[ $(calls) == *"ssh "*"-N -L 5432:localhost:5432 $USER@192.168.122.50"* ]]
	VM_EXISTS=1 run "$VM" tunnel rice 5432 5433
	[[ $(calls) == *"-N -L 5433:localhost:5432 tester@192.168.122.50"* ]]
}

@test "anything else goes to virsh on the system connection" {
	run "$VM" snapshot-list web
	[[ $(calls) == *"virsh -c qemu:///system snapshot-list web"* ]]
}
