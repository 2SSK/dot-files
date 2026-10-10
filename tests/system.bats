#!/usr/bin/env bats
# packages/system.sh against a throwaway root, with fake sudo/systemctl/virsh/usermod/sysctl.

setup() {
	# never the real login screen or boot menu (system.sh shares their backgrounds and colours with us)
	export DESKTOP_SDDM_DIR="$BATS_TEST_TMPDIR/no-sddm" DESKTOP_GRUB_DIR="$BATS_TEST_TMPDIR/no-grub"
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

@test "libvirt: a network that can't start is a warning, not a failure" {
	libvirt_fakes broken
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "virsh $*" >>"$CALLS"\ncase "$*" in *net-info*) printf "Active: no\\nAutostart: yes\\n" ;; *net-start*) echo "error: Network is already in use by interface eth0" >&2; exit 1 ;; esac\n' >"$BATS_TEST_TMPDIR/bin/virsh"
	run "$SYSTEM" libvirt
	[ "$status" -eq 0 ]
	[[ $output == *"event=network_not_started"*"already in use by interface eth0"* ]]
	grep -q "usermod -aG libvirt $USER" "$CALLS" # the rest still ran
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
	[ -f "$theme/select_w.png" ]
	[ -f "$theme/select_c.png" ]
	[ -f "$theme/select_e.png" ]
	[ ! -e "$theme/select_n.png" ] # top and bottom pieces would overlap the next entry
	[ -f "$theme/menu.pf2" ]
	grep -qx 'GRUB_THEME="/boot/grub/themes/desktop/theme.txt"' "$SYSTEM_ROOT/etc/default/grub"
	grep -qx 'GRUB_GFXMODE=auto' "$SYSTEM_ROOT/etc/default/grub"
	grep -qx 'GRUB_TERMINAL_OUTPUT="gfxterm"' "$SYSTEM_ROOT/etc/default/grub"
	# one entry per distro; the other kernels and fallbacks under Advanced options
	grep -qx 'GRUB_DISABLE_SUBMENU=false' "$SYSTEM_ROOT/etc/default/grub"
	grep -q "grub-mkconfig -o $SYSTEM_ROOT/boot/grub/grub.cfg" "$CALLS"
	rm "$CALLS"
	run "$SYSTEM" grub
	[[ $output == *"already in place"* ]]
	[ ! -e "$CALLS" ]
}

@test "grub: the background is installed as the user's, so a new wallpaper can replace it" {
	grub_fakes
	# sudo records the installs it runs
	# shellcheck disable=SC2016
	printf '#!/bin/sh
[ "$1" = install ] && echo "sudo $*" >>"$CALLS"
"$@"
' >"$BATS_TEST_TMPDIR/bin/sudo"
	run "$SYSTEM" grub
	[ "$status" -eq 0 ]
	grep -q "^sudo install -D -m 644 -o $(id -un) -g $(id -gn) .*/background.jpg $SYSTEM_ROOT/boot/grub/themes/desktop/background.jpg" "$CALLS"
	! grep -q "^sudo install -D -m 644 -o .*/theme.txt" "$CALLS"
}

@test "grub: a serial console stays, and the themed screen is added to it" {
	grub_fakes
	printf '\nGRUB_TERMINAL="serial console"\n' >>"$SYSTEM_ROOT/etc/default/grub"
	run "$SYSTEM" grub
	[ "$status" -eq 0 ]
	grep -qx 'GRUB_TERMINAL_INPUT="serial console"' "$SYSTEM_ROOT/etc/default/grub"
	grep -qx 'GRUB_TERMINAL_OUTPUT="gfxterm serial"' "$SYSTEM_ROOT/etc/default/grub"
	grep -qx '#GRUB_TERMINAL="serial console"' "$SYSTEM_ROOT/etc/default/grub"
	grep -qx 'GRUB_TERMINAL="serial console"' "$SYSTEM_ROOT/etc/default/grub.pre-desktop"
}

@test "unknown part is a usage error" {
	run "$SYSTEM" bogus
	[ "$status" -eq 2 ]
}

sddm_fakes() { # a rendered theme, and a fake magick that copies the image
	export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	XDG_STATE_HOME="$XDG_STATE_HOME" python3 "$BATS_TEST_DIRNAME/../.local/lib/desktop/theme_render.py" render kanagawa dark
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "magick $*" >>"$CALLS"\nfor last; do :; done\ncp "$1" "$last"\n' >"$BATS_TEST_TMPDIR/bin/magick"
	chmod +x "$BATS_TEST_TMPDIR/bin/magick"
}

@test "sddm: installs the theme, its colours and the wallpaper, and selects it" {
	sddm_fakes
	run "$SYSTEM" sddm
	[ "$status" -eq 0 ]
	local dir="$SYSTEM_ROOT/usr/share/sddm/themes/desktop"
	[ -f "$dir/Main.qml" ]
	[ -f "$dir/metadata.desktop" ]
	grep -qx 'Current=desktop' "$SYSTEM_ROOT/etc/sddm.conf.d/10-desktop.conf"
	# the theme reads the battery from sysfs, which QML only allows with this in the greeter's environment
	grep -qx 'GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1' "$SYSTEM_ROOT/etc/sddm.conf.d/20-desktop-greeter.conf"
}

@test "sddm: colours and wallpaper live in a folder the user owns, so theme set can update them" {
	sddm_fakes
	run "$SYSTEM" sddm
	[ "$status" -eq 0 ]
	local dir="$SYSTEM_ROOT/usr/share/sddm/themes/desktop" shared="$SYSTEM_ROOT/var/lib/desktop/sddm"
	[ "$(readlink "$dir/theme.conf")" = /var/lib/desktop/sddm/theme.conf ]
	[ "$(readlink "$dir/background.jpg")" = /var/lib/desktop/sddm/background.jpg ]
	[ "$(stat -c %U "$shared")" = "$(id -un)" ]
	[ "$(stat -c %a "$shared/background.jpg")" = 644 ]
	grep -qx 'bg=#1f1f28' "$shared/theme.conf"
}

@test "sddm: an existing /etc/sddm.conf theme is switched in place, the original kept; reruns change nothing" {
	sddm_fakes
	mkdir -p "$SYSTEM_ROOT/etc"
	printf '[Theme]\nCurrent=voidsddm\n' >"$SYSTEM_ROOT/etc/sddm.conf"
	run "$SYSTEM" sddm
	[ "$status" -eq 0 ]
	grep -qx 'Current=desktop' "$SYSTEM_ROOT/etc/sddm.conf"
	grep -qx 'Current=voidsddm' "$SYSTEM_ROOT/etc/sddm.conf.pre-desktop"
	[ ! -e "$SYSTEM_ROOT/etc/sddm.conf.d/10-desktop.conf" ]
	run "$SYSTEM" sddm
	[[ $output == *"sddm: already in place"* ]]
}

@test "lid: closing it only locks, and logind rereads its config without a restart" {
	run "$SYSTEM" lid
	[ "$status" -eq 0 ]
	grep -qx 'HandleLidSwitch=lock' "$SYSTEM_ROOT/etc/systemd/logind.conf.d/10-lid.conf"
	grep -qx 'HandleLidSwitchExternalPower=lock' "$SYSTEM_ROOT/etc/systemd/logind.conf.d/10-lid.conf"
	grep -q 'systemctl kill --signal=HUP systemd-logind.service' "$CALLS"
	! grep -q 'restart' "$CALLS"
	rm "$CALLS"
	run "$SYSTEM" lid
	[[ $output == *"lid: already in place"* ]]
	[ ! -e "$CALLS" ]
}

timeshift_conf() { # a timeshift.json as timeshift writes it: daily, 5 kept
	mkdir -p "$SYSTEM_ROOT/etc/timeshift"
	printf '{\n  "btrfs_mode" : "true",\n  "schedule_daily" : "true",\n  "schedule_hourly" : "true",\n  "count_daily" : "5",\n  "count_weekly" : "3"\n}' \
		>"$SYSTEM_ROOT/etc/timeshift/timeshift.json"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "visudo $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/visudo"
	chmod +x "$BATS_TEST_TMPDIR/bin/visudo"
}

@test "timeshift: lets the user list snapshots without a password, nothing more" {
	timeshift_conf
	run "$SYSTEM" timeshift
	[ "$status" -eq 0 ]
	rule="$SYSTEM_ROOT/etc/sudoers.d/90-desktop-timeshift"
	grep -qx "$(id -un) ALL=(root) NOPASSWD: /usr/bin/timeshift --list --scripted" "$rule"
	[ "$(grep -vc '^#' "$rule")" -eq 1 ]
	[ "$(stat -c %a "$rule")" = 440 ]
	grep -q "^visudo -cf " "$CALLS"
	rm "$CALLS"
	run "$SYSTEM" timeshift
	[[ $output == *"already in place"* ]]
}

@test "timeshift: keeps 3 daily and 1 weekly, nothing hourly, the rest of its config as it was" {
	timeshift_conf
	run "$SYSTEM" timeshift
	[ "$status" -eq 0 ]
	conf="$SYSTEM_ROOT/etc/timeshift/timeshift.json"
	[ "$(jq -r '[.schedule_daily, .count_daily, .schedule_weekly, .count_weekly, .schedule_hourly, .schedule_boot, .schedule_monthly] | join(" ")' "$conf")" = "true 3 true 1 false false false" ]
	[ "$(jq -r .btrfs_mode "$conf")" = true ]
	grep -qx 'maxSnapshots=3' "$SYSTEM_ROOT/etc/timeshift-autosnap.conf"
	grep -qx 'updateGrub=false' "$SYSTEM_ROOT/etc/timeshift-autosnap.conf"
}

@test "timeshift: in timeshift's own layout, the same settings count as in place" {
	timeshift_conf
	"$SYSTEM" timeshift
	conf="$SYSTEM_ROOT/etc/timeshift/timeshift.json"
	jq --indent 4 . "$conf" >"$conf.new" && mv "$conf.new" "$conf"
	run "$SYSTEM" timeshift
	[[ $output == *"already in place"* ]]
}

@test "timeshift: not set up yet says so" {
	run "$SYSTEM" timeshift
	[ "$status" -ne 0 ]
	[[ $output == *"timeshift_not_set_up"* ]]
}

subvolume_fakes() { # btrfs makes folders and remembers them as subvolumes; the root is btrfs
	local bin="$BATS_TEST_TMPDIR/bin"
	export SUBVOLS="$BATS_TEST_TMPDIR/subvols" HOME="$BATS_TEST_TMPDIR/home"
	: >"$SUBVOLS"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\ncase "$2" in\nshow) grep -qxF "$3" "$SUBVOLS" ;;\ncreate) mkdir "$3" && echo "$3" >>"$SUBVOLS" ;;\nesac\n' >"$bin/btrfs"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "chattr $*" >>"$CALLS"\n' >"$bin/chattr"
	printf '#!/bin/sh\necho btrfs\n' >"$bin/findmnt"
	chmod +x "$bin"/*
	mkdir -p "$SYSTEM_ROOT/var/lib/libvirt/images" "$SYSTEM_ROOT/var/lib/docker/overlay2" "$HOME/.cache/app"
	echo disk >"$SYSTEM_ROOT/var/lib/libvirt/images/vm.qcow2"
	echo layer >"$SYSTEM_ROOT/var/lib/docker/overlay2/l"
	echo cached >"$HOME/.cache/app/c"
	chmod 710 "$SYSTEM_ROOT/var/lib/docker"
}

@test "subvolumes: VM disks, docker and ~/.cache move into subvolumes, the originals kept" {
	subvolume_fakes
	run "$SYSTEM" subvolumes
	[ "$status" -eq 0 ]
	for dir in "$SYSTEM_ROOT/var/lib/libvirt/images" "$SYSTEM_ROOT/var/lib/docker" "$HOME/.cache"; do
		grep -qxF "$dir" "$SUBVOLS"
		[ -d "$dir.old-subvolume" ] # kept until checked
		[[ $output == *"sudo rm -rf $dir.old-subvolume"* ]]
	done
	[ "$(cat "$SYSTEM_ROOT/var/lib/libvirt/images/vm.qcow2")" = disk ]
	[ "$(cat "$SYSTEM_ROOT/var/lib/docker/overlay2/l")" = layer ]
	[ "$(cat "$HOME/.cache/app/c")" = cached ]
	[ "$(stat -c %a "$SYSTEM_ROOT/var/lib/docker")" = 710 ]
	grep -qx "chattr +C $SYSTEM_ROOT/var/lib/libvirt/images" "$CALLS" # no copy-on-write for VM disks
	[ "$(grep -c '^chattr' "$CALLS")" -eq 1 ]
	grep -q "systemctl stop docker.socket docker.service" "$CALLS"
	grep -q "systemctl start docker.service" "$CALLS"
}

@test "subvolumes: a second run changes nothing" {
	subvolume_fakes
	"$SYSTEM" subvolumes
	rm "$CALLS"
	run "$SYSTEM" subvolumes
	[ "$status" -eq 0 ]
	[[ $output == *"already in place"* ]]
}

@test "subvolumes: a leftover from a run that stopped half way stops it" {
	subvolume_fakes
	mkdir "$HOME/.cache.old-subvolume"
	run "$SYSTEM" subvolumes
	[ "$status" -ne 0 ]
	[[ $output == *"subvolume_leftover"* ]]
	[ -f "$HOME/.cache/app/c" ] # untouched
}

@test "subvolumes: running VMs stop it before anything moves" {
	subvolume_fakes
	printf '#!/bin/sh\necho rice\n' >"$BATS_TEST_TMPDIR/bin/virsh"
	run "$SYSTEM" subvolumes
	[ "$status" -ne 0 ]
	[[ $output == *"vms_running"* ]]
	[ ! -s "$SUBVOLS" ]
}

@test "power: TLP's settings in, auto-cpufreq off, TLP on and applied" {
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "systemctl $*" >>"$CALLS"\ncase "$*" in *is-enabled*auto-cpufreq*) exit 0 ;; *is-enabled*tlp*) exit 1 ;; esac\n' >"$BATS_TEST_TMPDIR/bin/systemctl"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "tlp $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/tlp"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	run "$SYSTEM" power
	[ "$status" -eq 0 ]
	local conf="$SYSTEM_ROOT/etc/tlp.d/10-desktop.conf"
	# quiet (the power saver, without turbo) on the charger and on battery
	grep -qx 'TLP_PROFILE_AC=SAV' "$conf"
	grep -qx 'TLP_PROFILE_BAT=SAV' "$conf"
	grep -qx 'PLATFORM_PROFILE_ON_BAT=balanced' "$conf"
	grep -qx 'CPU_BOOST_ON_SAV=0' "$conf"
	grep -qx 'PLATFORM_PROFILE_ON_SAV=quiet' "$conf"
	grep -qx 'STOP_CHARGE_THRESH_BAT1=80' "$conf"
	# the shell's power page: the charge-limit helper, root's, and the passwordless rule for it and the profiles
	[ -x "$SYSTEM_ROOT/usr/local/bin/desktop-charge-limit" ]
	grep -qx "$(id -un) ALL=(root) NOPASSWD: /usr/bin/tlp performance, /usr/bin/tlp balanced, /usr/bin/tlp power-saver, /usr/local/bin/desktop-charge-limit" "$SYSTEM_ROOT/etc/sudoers.d/90-desktop-power"
	grep -qx "systemctl disable --now auto-cpufreq.service" "$CALLS"
	grep -qx "systemctl enable --now tlp.service" "$CALLS"
	grep -qx "tlp start" "$CALLS"
}

@test "power: already set up changes nothing" {
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "systemctl $*" >>"$CALLS"\ncase "$*" in *is-enabled*auto-cpufreq*) exit 1 ;; esac\n' >"$BATS_TEST_TMPDIR/bin/systemctl"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "tlp $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/tlp"
	chmod +x "$BATS_TEST_TMPDIR/bin/tlp"
	"$SYSTEM" power
	rm -f "$CALLS"
	run "$SYSTEM" power
	[[ $output == *"already in place"* ]]
	! grep -q -- "--now" "$CALLS"
}

@test "timeshift: the rule comes after the installer's, an earlier one before it goes" {
	timeshift_conf
	mkdir -p "$SYSTEM_ROOT/etc/sudoers.d"
	echo old >"$SYSTEM_ROOT/etc/sudoers.d/10-desktop-timeshift"
	run "$SYSTEM" timeshift
	[ "$status" -eq 0 ]
	[ ! -e "$SYSTEM_ROOT/etc/sudoers.d/10-desktop-timeshift" ]
	[[ 90-desktop-timeshift > 10-installer ]] # sudo reads them in name order; the last match wins
	[ -f "$SYSTEM_ROOT/etc/sudoers.d/90-desktop-timeshift" ]
}
