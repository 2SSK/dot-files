#!/usr/bin/env bash
# System-level setup (sudo): the memory safety net, a UTF-8 locale, libvirt, docker, the lid, power (TLP), snapshots
# (Timeshift and the subvolumes it leaves out), the boot menu and the login screen. Installs the tracked files under
# system/ into / and enables services; a no-op when everything is already in place.
# usage: system.sh            every part that applies to this machine (system.sh --plan lists them)
#        system.sh <part>...  just those: memory locale services power lid timeshift grub sddm libvirt docker subvolumes
#        system.sh grub --preview  the boot menu in a small QEMU window (nothing installed)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/screens.sh
source "$here/../.local/lib/desktop/screens.sh"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/state.sh
source "$here/../.local/lib/desktop/state.sh"
((EUID != 0)) || die run_as_user msg='run it as your user: it reads your theme and calls sudo itself'
src="$here/../system"
root="${SYSTEM_ROOT:-}" # tests point this at a scratch directory

changed=0

put() { # <path under system/> [mode]: install it into / when missing or different
	local dest="$root/$1"
	cmp -s "$src/$1" "$dest" 2>/dev/null && return 0
	sudo install -D -m "${2:-644}" "$src/$1" "$dest"
	log_info installed path="/$1"
	changed=1
}

memory() {
	put etc/systemd/zram-generator.conf
	put etc/sysctl.d/99-zram.conf
	put etc/systemd/system/user@.service.d/10-oomd.conf
	put etc/systemd/system/-.slice.d/10-oomd.conf
	((changed)) || return 0
	sudo systemctl daemon-reload
	# now if it can be: right after a kernel upgrade (setup's own, on Arch) its module can't load until a reboot
	sudo systemctl start systemd-zram-setup@zram0.service 2>/dev/null ||
		log_warn zram_after_reboot msg='zram starts at the next boot'
	sudo sysctl --quiet --load "$root/etc/sysctl.d/99-zram.conf" 2>/dev/null || true
	sudo systemctl enable --now systemd-oomd.service
}

sudoers() { # <file under /etc/sudoers.d> <comment> <rule>: install the rule, checked by visudo first
	local tmp dest="$root/etc/sudoers.d/$1"
	tmp="$(mktemp)"
	printf '# %s\n%s\n' "$2" "$3" >"$tmp"
	# sudoers.d is root's alone to read
	if sudo cmp -s "$tmp" "$dest" 2>/dev/null; then rm -f "$tmp" && return 0; fi
	visudo -cf "$tmp" >/dev/null || { rm -f "$tmp" && die sudoers_invalid path="$dest"; }
	sudo install -D -m 440 "$tmp" "$dest"
	rm -f "$tmp"
	log_info installed path="/etc/sudoers.d/$1"
	changed=1
}

timeshift_list() { # the settings page lists snapshots without a password; making, deleting and restoring still ask
	# sudo reads sudoers.d in name order and the last rule that matches wins: after the installer's
	# "%wheel ALL=(ALL) ALL" (EndeavourOS's 10-installer), or that one asks for the password again
	local first="$root/etc/sudoers.d/10-desktop-timeshift"
	if sudo test -e "$first"; then # where an earlier version put it, before the installer's rule
		sudo rm -f "$first"
		changed=1
	fi
	sudoers 90-desktop-timeshift "packages/system.sh timeshift: the shell's settings page reads the snapshot list" \
		"$(id -un) ALL=(root) NOPASSWD: /usr/bin/timeshift --list --scripted"
}

# What is kept: the last 3 days, one from about a week ago, and (timeshift-autosnap, its config in
# system/) the last 3 from before a pacman upgrade. Btrfs snapshots cost only what changed since, so
# a few more points back are cheap; hourly, boot and monthly ones would be clutter. Timeshift drops
# what is past these counts at its next scheduled check (cron, hourly).
timeshift_schedule() {
	local conf="$root/etc/timeshift/timeshift.json" tmp
	[[ -f $conf ]] || die timeshift_not_set_up msg='run timeshift once to choose the disk, then this again'
	local want='.schedule_daily = "true" | .count_daily = "3" | .schedule_weekly = "true" | .count_weekly = "1"
		| .schedule_hourly = "false" | .schedule_boot = "false" | .schedule_monthly = "false"
		| .btrfs_use_qgroup = "false"'
	# compared by value: timeshift rewrites the file in its own layout
	jq -e "($want) == ." "$conf" >/dev/null && return 0
	tmp="$(mktemp)"
	jq "$want" "$conf" >"$tmp"
	sudo install -m 644 "$tmp" "$conf"
	rm -f "$tmp"
	log_info installed path=/etc/timeshift/timeshift.json daily=3 weekly=1
	changed=1
}

# btrfs quotas (qgroups) off: Timeshift turns them on to show snapshot sizes, but then deleting a
# snapshot can leave the accounting inconsistent, and the whole disk is rescanned while every write
# stalls (shells and nvim froze for minutes after each daily snapshot). Turned back on with
# `btrfs quota enable /` should sizes be wanted; Timeshift itself works without them.
quota_off() {
	compgen -G "$root/sys/fs/btrfs/*/qgroups" >/dev/null || return 0
	sudo btrfs quota disable "$root/"
	log_info quota_off msg='btrfs quotas disabled'
	changed=1
}

timeshift() {
	timeshift_list
	timeshift_schedule
	quota_off
	put etc/timeshift-autosnap.conf
}

# Folders whose data changes all day, made btrfs subvolumes of their own: a snapshot (Timeshift's of
# / and /home) leaves nested subvolumes out, so snapshots don't keep every old version of a VM disk,
# Docker's layers or ~/.cache. What is there is copied into the new subvolume and the original kept
# beside it (<folder>.old-subvolume) until you have checked and removed it; a missing folder is made
# empty. A no-op once each is a subvolume.
is_subvolume() { sudo btrfs subvolume show "$1" >/dev/null 2>&1; }

make_subvolume() { # <dir> [nocow]: the folder's contents, in a new subvolume at the same path
	local dir=$1 old="$1.old-subvolume"
	if [[ ! -e $dir ]]; then
		sudo btrfs subvolume create "$dir" >/dev/null
		[[ ${2:-} != nocow ]] || sudo chattr +C "$dir"
	else
		[[ ! -e $old ]] || die subvolume_leftover path="$old" msg='an earlier run stopped half way: check it, then move it away'
		sudo mv "$dir" "$old"
		sudo btrfs subvolume create "$dir" >/dev/null
		sudo chown --reference="$old" "$dir"
		sudo chmod --reference="$old" "$dir"
		# no copy-on-write (VM disks): set on the empty folder, the copies inherit it
		[[ ${2:-} != nocow ]] || sudo chattr +C "$dir"
		sudo cp -a --reflink=auto "$old/." "$dir/" || die subvolume_copy_failed path="$dir" msg="the original is in $old"
		kept+=("$old")
	fi
	log_info subvolume path="$dir"
	changed=1
}

subvolumes() {
	local images="$root/var/lib/libvirt/images" docker="$root/var/lib/docker" cache="$HOME/.cache" was_active=0 kept=()
	[[ $(findmnt -no FSTYPE --target "${root:-/}") == btrfs ]] || die not_btrfs msg='subvolumes are a btrfs thing'
	if [[ -d ${images%/*} ]] && ! is_subvolume "$images"; then
		if command -v virsh >/dev/null && [[ -n $(sudo virsh -c qemu:///system list --name --state-running) ]]; then
			die vms_running msg='shut the VMs down first (virsh list)'
		fi
		make_subvolume "$images" nocow
	fi
	if [[ -d ${docker%/*} ]] && ! is_subvolume "$docker"; then
		if systemctl is-active --quiet docker.service; then
			was_active=1
			sudo systemctl stop docker.socket docker.service
		fi
		make_subvolume "$docker"
		((!was_active)) || sudo systemctl start docker.service
	fi
	# apps write their cache all the time: close the browsers first
	is_subvolume "$cache" || make_subvolume "$cache"
	((${#kept[@]})) || return 0
	echo "The originals are kept. Once the VMs, Docker and your apps work, remove them with:"
	printf '  sudo rm -rf %q\n' "${kept[@]}"
}

power() { # TLP alone (auto-cpufreq fights it over the CPU), with system/etc/tlp.d's settings
	put etc/tlp.d/10-desktop.conf
	put etc/modprobe.d/btusb.conf
	# the shell's power controls (desktop-power): TLP's three profiles and the charge limit, without
	# a password; the helper is root's, so the rule can't be pointed at anything else
	put usr/local/bin/desktop-charge-limit 755
	sudoers 90-desktop-power "packages/system.sh power: the shell's power profile and charge limit" \
		"$(id -un) ALL=(root) NOPASSWD: /usr/bin/tlp performance, /usr/bin/tlp balanced, /usr/bin/tlp power-saver, /usr/local/bin/desktop-charge-limit"
	if systemctl is-enabled --quiet auto-cpufreq.service 2>/dev/null; then
		sudo systemctl disable --now auto-cpufreq.service
		changed=1
	fi
	if ! systemctl is-enabled --quiet tlp.service 2>/dev/null; then
		sudo systemctl enable --now tlp.service
		changed=1
	fi
	((changed)) || return 0
	sudo tlp start >/dev/null # the settings now, not at the next plug or boot
	# and the Bluetooth chip awake now (the module option holds from the next boot)
	local d
	for d in "$root"/sys/bus/usb/drivers/btusb/*:*; do
		[[ -e $d/../power/control ]] && echo on | sudo tee "$d/../power/control" >/dev/null
	done
	return 0
}

lid() { # closing the lid only locks; logind rereads its config on SIGHUP (a restart would end sessions)
	put etc/systemd/logind.conf.d/10-lid.conf
	((changed)) || return 0
	sudo systemctl kill --signal=HUP systemd-logind.service
}

libvirt() {
	# The daemons: one socket per driver (Arch and Fedora)
	local unit units=(virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket)
	for unit in "${units[@]}"; do
		systemctl is-enabled --quiet "$unit" 2>/dev/null && systemctl is-active --quiet "$unit" && continue
		sudo systemctl enable --now "$unit"
		changed=1
	done
	# The NAT network VMs get their address from, started now and at every boot
	local info
	info="$(sudo virsh -c qemu:///system net-info default 2>/dev/null)" || die no_default_network
	if ! grep -qE '^Autostart: +yes' <<<"$info"; then
		sudo virsh -c qemu:///system net-autostart default >/dev/null
		changed=1
	fi
	if ! grep -qE '^Active: +yes' <<<"$info"; then
		local err
		if err="$(sudo virsh -c qemu:///system net-start default 2>&1 >/dev/null)"; then
			changed=1
		else # e.g. inside a VM whose own network already uses 192.168.122.0/24; VMs still work elsewhere
			log_warn network_not_started msg="${err//$'\n'/ }"
		fi
	fi
	# firewalld rejects the VMs' DHCP and DNS unless the bridge is in libvirt's zone; libvirt only
	# adds it at runtime, which a firewalld reload forgets
	if systemctl is-active --quiet firewalld 2>/dev/null &&
		[[ $(sudo firewall-cmd --permanent --get-zone-of-interface=virbr0 2>/dev/null) != libvirt ]]; then
		sudo firewall-cmd --quiet --permanent --zone=libvirt --add-interface=virbr0
		sudo firewall-cmd --quiet --reload
		changed=1
	fi
	# virsh and vm without sudo
	if ! id -nG "$USER" | tr ' ' '\n' | grep -qx libvirt; then
		sudo usermod -aG libvirt "$USER"
		log_warn relogin msg='added to the libvirt group; takes effect at the next login'
		changed=1
	fi
}

docker_daemon() {
	# Socket-activated: the daemon starts on first use. The docker group is root-equivalent.
	if ! systemctl is-enabled --quiet docker.socket 2>/dev/null || ! systemctl is-active --quiet docker.socket; then
		sudo systemctl enable --now docker.socket
		changed=1
	fi
	if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
		sudo usermod -aG docker "$USER"
		log_warn relogin msg='added to the docker group; takes effect at the next login'
		changed=1
	fi
}

grub_set() { # <KEY> <value>: set a line in /etc/default/grub (its original kept as grub.pre-desktop)
	local file="$root/etc/default/grub" line="$1=$2"
	grep -qx "$line" "$file" && return 0
	[[ -e $file.pre-desktop ]] || sudo cp "$file" "$file.pre-desktop"
	if grep -q "^#\?$1=" "$file"; then
		sudo sed -i "s|^#\?$1=.*|$line|" "$file"
	else
		[[ -z $(tail -c 1 "$file") ]] || echo | sudo tee -a "$file" >/dev/null # missing final newline
		echo "$line" | sudo tee -a "$file" >/dev/null
	fi
	changed=1
}

grub_unset() { # <KEY>: drop its line from /etc/default/grub
	local file="$root/etc/default/grub"
	grep -q "^$1=" "$file" || return 0
	[[ -e $file.pre-desktop ]] || sudo cp "$file" "$file.pre-desktop"
	sudo sed -i "/^$1=/d" "$file"
	changed=1
}

grub_font() { # <grub-mkfont> <fontconfig pattern> <size> <name> <out.pf2>: the name grub-theme.txt uses
	local mkfont=$1 match got
	match="$(fc-match -f '%{file}:%{index}' "$2")"
	"$mkfont" -n "$4" -i "${match##*:}" -s "$3" -o "$5" "${match%:*}" >/dev/null 2>&1 || die grub_font font="${match%:*}"
	# the name GRUB knows it by is in the file's NAME section: family, style, size
	got="$(python3 -c 'import sys; d = open(sys.argv[1], "rb").read(); i = d.index(b"NAME") + 4
n = int.from_bytes(d[i:i + 4], "big"); print(d[i + 4:i + 4 + n].split(b"\0")[0].decode())' "$5")"
	[[ $got == "$4 Regular $3" ]] || die grub_font_name want="$4 Regular $3" got="$got"
}

grub_build() { # <dir> <grub-mkfont>: the theme from the current palette (its dark colours), no root
	local out=$1 family mode
	read -r family mode < <(current_theme)
	python3 "$here/../.local/lib/desktop/theme_render.py" render "$family" "$mode" # a render from before the template
	mkdir -p "$out"
	grub_font "$2" 'Inter:style=Medium' 22 Desktop "$out/menu.pf2"
	grub_font "$2" 'Inter:style=Regular' 15 DesktopHint "$out/hint.pf2"
	boot_theme "$desktop_state/theme/grub-theme.txt" "$out"
}

# The boot menu: the theme (theme set keeps its theme.txt and background in step, so those two are
# the user's), graphical output, and on btrfs the first entry instead of the last one chosen (GRUB
# can't write its saved choice there: "sparse file not allowed"). Arch: entries named Linux, Linux
# LTS and Linux (fallback) by 09_desktop in place of 10_linux's, and the firmware's own boot entries
# hidden (EndeavourOS lists them). A no-op when nothing changed.
grub_theme() {
	local boot=/boot/grub mkfont=grub-mkfont mkconfig=grub-mkconfig check=grub-script-check
	[[ -d $root/boot/grub2 ]] && boot=/boot/grub2 mkfont=grub2-mkfont mkconfig=grub2-mkconfig check=grub2-script-check
	local dest="$root$boot/themes/desktop" tmp f owner=() entries=0
	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064 # expand now: tmp is local
	trap "rm -rf '$tmp'" RETURN
	grub_build "$tmp" "$mkfont"
	for f in "$tmp"/*; do
		owner=()
		[[ ${f##*/} == theme.txt || ${f##*/} == background.png ]] && owner=(-o "$(id -un)" -g "$(id -gn)")
		cmp -s "$f" "$dest/${f##*/}" 2>/dev/null && { ((${#owner[@]} == 0)) || [[ -O $dest/${f##*/} ]]; } && continue
		sudo install -D -m 644 "${owner[@]}" "$f" "$dest/${f##*/}"
		changed=1
	done
	for f in "$dest"/*; do # what an earlier version of the theme left behind
		[[ -e $f && ! -e $tmp/${f##*/} ]] || continue
		sudo rm "$f"
		changed=1
	done

	grub_set GRUB_THEME "\"$boot/themes/desktop/theme.txt\""
	# A serial console (cloud images, servers) stays: GRUB_TERMINAL sets input and output at once, so
	# it is split into its input and an output that adds the themed screen to the serial port
	local serial
	serial="$(sed -n 's/^GRUB_TERMINAL=\(.*serial.*\)/\1/p' "$root/etc/default/grub")"
	if [[ -n $serial ]]; then
		grub_set GRUB_TERMINAL_INPUT "$serial"
		grub_set GRUB_TERMINAL_OUTPUT '"gfxterm serial"'
		sudo sed -i 's/^GRUB_TERMINAL=/#GRUB_TERMINAL=/' "$root/etc/default/grub"
	else
		grub_set GRUB_TERMINAL_OUTPUT '"gfxterm"'
	fi
	if [[ $(findmnt -no FSTYPE -T "$root/boot" 2>/dev/null) == btrfs ]]; then
		grub_set GRUB_DEFAULT 0
		grub_unset GRUB_SAVEDEFAULT
	fi

	if [[ $boot == /boot/grub && -e $root/etc/grub.d/10_linux ]] && compgen -G "$root/boot/vmlinuz-linux*" >/dev/null; then
		entries=1
		put etc/grub.d/09_desktop 755
		if [[ -x $root/etc/grub.d/10_linux ]]; then
			sudo chmod -x "$root/etc/grub.d/10_linux"
			changed=1
		fi
		# a grub update would otherwise bring 10_linux back, executable, beside 09_desktop
		if [[ -f $root/etc/pacman.conf ]] && ! grep -q 'etc/grub.d/10_linux' "$root/etc/pacman.conf"; then
			if grep -q '^NoExtract *=' "$root/etc/pacman.conf"; then
				sudo sed -i '0,/^NoExtract *=/ s|^\(NoExtract *=.*\)$|\1 etc/grub.d/10_linux|' "$root/etc/pacman.conf"
			else
				sudo sed -i '/^\[options\]/a NoExtract = etc/grub.d/10_linux' "$root/etc/pacman.conf"
			fi
			changed=1
		fi
		grub_set GRUB_DISABLE_BOOTNEXT '"true"'
	fi

	((changed)) || return 0
	sudo "$mkconfig" -o "$root$boot/grub.cfg"
	# never a menu without Linux in it: GRUB's own entries come back when ours didn't make it
	if ((entries)) && ! sudo grep -q "^menuentry 'Linux'" "$root$boot/grub.cfg"; then
		sudo chmod +x "$root/etc/grub.d/10_linux"
		sudo "$mkconfig" -o "$root$boot/grub.cfg"
		die grub_entries msg="09_desktop wrote no entries; GRUB's own are back"
	fi
	sudo "$check" "$root$boot/grub.cfg"
}

grub_preview() { # the theme in a small QEMU machine, in a window (no root, nothing installed)
	local tmp
	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064 # expand now: tmp is local
	trap "rm -rf '$tmp'" RETURN
	grub_build "$tmp/iso/boot/grub/themes/desktop" grub-mkfont
	cat >"$tmp/iso/boot/grub/grub.cfg" <<-'EOF'
		insmod all_video
		insmod gfxterm
		insmod png
		set gfxmode=1920x1080,auto
		terminal_output gfxterm
		loadfont /boot/grub/themes/desktop/menu.pf2
		loadfont /boot/grub/themes/desktop/hint.pf2
		set theme=/boot/grub/themes/desktop/theme.txt
		set timeout=60
		menuentry "Linux" { true }
		menuentry "Linux LTS" { true }
		menuentry "Linux (fallback)" { true }
		menuentry "UEFI Firmware Settings" { true }
	EOF
	grub-mkrescue -o "$tmp/preview.iso" "$tmp/iso" >/dev/null 2>&1 || die grub_preview msg='grub-mkrescue failed (needs xorriso and mtools)'
	qemu-system-x86_64 -m 256 -cdrom "$tmp/preview.iso" -vga std -name 'GRUB preview'
}

sddm_theme() { # the login screen in the desktop theme; theme set keeps its colours in step
	local state="$desktop_state" dir=usr/share/sddm/themes/desktop family mode
	read -r family mode < <(current_theme)
	# a render from before this template existed lacks it; an unchanged render is a no-op
	python3 "$here/../.local/lib/desktop/theme_render.py" render "$family" "$mode"
	put $dir/Main.qml
	put $dir/metadata.desktop

	# Colours and wallpaper live in a folder the user owns, which sddm can read (it can't read the
	# home directory): theme set then updates them without sudo. The theme links to them.
	local shared=/var/lib/desktop/sddm file
	if [[ ! -O $root$shared ]]; then
		sudo install -d -o "$(id -un)" -g "$(id -gn)" -m 755 "$root$shared"
		changed=1
	fi
	cmp -s "$state/theme/sddm-theme.conf" "$root$shared/theme.conf" || { install -m 644 "$state/theme/sddm-theme.conf" "$root$shared/theme.conf" && changed=1; }

	local wallpaper tmp
	wallpaper="$(current_wallpaper)"
	tmp="$(mktemp --suffix=.jpg)"
	# shellcheck disable=SC2064 # expand now: tmp is local
	trap "rm -f '$tmp'" RETURN
	login_background "$wallpaper" "$tmp"
	cmp -s "$tmp" "$root$shared/background.jpg" || { install -m 644 "$tmp" "$root$shared/background.jpg" && changed=1; }

	for file in theme.conf background.jpg; do
		[[ $(readlink "$root/$dir/$file") == "$shared/$file" ]] && continue
		sudo ln -sfn "$shared/$file" "$root/$dir/$file"
		changed=1
	done

	# /etc/sddm.conf overrides sddm.conf.d, so a Current= there is changed in place (original kept)
	local conf="$root/etc/sddm.conf"
	if grep -q '^Current=' "$conf" 2>/dev/null; then
		if ! grep -qx 'Current=desktop' "$conf"; then
			[[ -e $conf.pre-desktop ]] || sudo cp "$conf" "$conf.pre-desktop"
			sudo sed -i 's|^Current=.*|Current=desktop|' "$conf"
			changed=1
		fi
	else
		put etc/sddm.conf.d/10-desktop.conf
	fi
	put etc/sddm.conf.d/20-desktop-greeter.conf # the battery on the login screen
}

services() { # what the desktop expects running: the login screen, Bluetooth and Wi-Fi (the shell's panels), the modules cleanup
	local lib=$root/usr/lib/systemd/system etc=$root/etc/systemd/system
	if [[ -f $lib/sddm.service && ! -L $etc/display-manager.service ]]; then
		sudo systemctl enable sddm.service && changed=1
	fi
	if [[ -f $lib/bluetooth.service && ! -L $etc/bluetooth.target.wants/bluetooth.service ]]; then
		sudo systemctl enable --now bluetooth.service && changed=1
	fi
	# kernel-modules-hook's: the old kernel's kept modules cleared at the next boot
	if [[ -f $lib/linux-modules-cleanup.service && ! -L $etc/basic.target.wants/linux-modules-cleanup.service ]]; then
		sudo systemctl enable linux-modules-cleanup.service && changed=1
	fi
	[[ -f $lib/NetworkManager.service && ! -L $etc/multi-user.target.wants/NetworkManager.service ]] || return 0
	# two network managers fight over the links: one already here is left alone
	if [[ -L $etc/multi-user.target.wants/systemd-networkd.service || -L $etc/multi-user.target.wants/connman.service ]]; then
		log_warn wifi_panel msg='the Wi-Fi panel needs NetworkManager; this system runs another network manager'
	else
		sudo systemctl enable --now NetworkManager.service && changed=1
	fi
}

locale() { # a UTF-8 system locale: ISO-8859 (en_IN alone) breaks icons and box drawing in terminals
	local conf=$root/etc/locale.conf gen=$root/etc/locale.gen line name value want=() set=()
	[[ -f $conf ]] && mapfile -t set < <(grep -E '^(LANG|LC_[A-Z]+)=' "$conf")
	((${#set[@]})) || set=(LANG=en_US)
	for line in "${set[@]}"; do
		name=${line%%=*} value=${line#*=} && value=${value//\"/}
		[[ ${value,,} == *.utf?8 ]] || changed=1
		want+=("$name=${value%%.*}.UTF-8")
	done
	((changed)) || return 0
	if [[ -f $gen ]]; then # Arch builds the locales it lists; Fedora ships them (glibc langpacks)
		for line in "${want[@]}"; do
			value=${line#*=} && value=${value%.UTF-8}
			grep -qE "^${value}\.UTF-8 UTF-8" "$gen" || sudo sed -i -E "s/^#[[:space:]]*(${value}\.UTF-8 UTF-8)/\1/" "$gen"
		done
		sudo locale-gen >/dev/null
	fi
	sudo localectl set-locale "${want[@]}"
	log_info locale_set locale="${want[0]#*=}" msg='takes effect at the next login'
}

# The parts that apply to this machine, in the order they run: what `system.sh` alone sets up.
# subvolumes is never among them: it moves folders' data, so it runs only when named.
plan() {
	local parts=(memory locale services)
	compgen -G "$root/sys/class/power_supply/BAT*" >/dev/null && parts+=(power lid)
	[[ -f $root/etc/timeshift/timeshift.json ]] && parts+=(timeshift)
	[[ -f $root/etc/default/grub ]] && parts+=(grub)
	[[ -x $root/usr/bin/sddm ]] && parts+=(sddm)
	[[ -x $root/usr/bin/virsh ]] && parts+=(libvirt)
	[[ -x $root/usr/bin/dockerd ]] && parts+=(docker)
	echo "${parts[*]}"
}

usage() {
	echo 'usage: system.sh [--plan | part...]   parts: memory locale services power lid timeshift grub sddm libvirt docker subvolumes' >&2
	echo '       system.sh grub --preview         (no args: every part that applies here; see --plan)' >&2
	exit 2
}

case ${1:-} in
--plan) plan && exit 0 ;;
-h | --help) usage ;;
grub) if [[ ${2:-} == --preview ]]; then grub_preview && exit 0; fi ;;
esac

parts=("$@")
((${#parts[@]})) || read -ra parts <<<"$(plan)"
for part in "${parts[@]}"; do
	case $part in memory | locale | services | power | lid | timeshift | grub | sddm | libvirt | docker | subvolumes) ;; *) usage ;; esac
done
for part in "${parts[@]}"; do
	changed=0
	case $part in
	memory) memory ;;
	locale) locale ;;
	services) services ;;
	libvirt) libvirt ;;
	docker) docker_daemon ;;
	lid) lid ;;
	power) power ;;
	timeshift) timeshift ;;
	subvolumes) subvolumes ;;
	grub) grub_theme ;;
	sddm) sddm_theme ;;
	esac
	if ((changed)); then echo "$part: set up"; else echo "$part: already in place"; fi
done
