#!/usr/bin/env bash
# System-level setup (sudo): the memory safety net and libvirt. Installs the tracked files
# under system/ into / and enables services; a no-op when everything is already in place.
# usage: system.sh memory|libvirt
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"
src="$here/../system"
root="${SYSTEM_ROOT:-}" # tests point this at a scratch directory

changed=0

put() { # <path under system/>: install it into / when missing or different
	local dest="$root/$1"
	cmp -s "$src/$1" "$dest" 2>/dev/null && return 0
	sudo install -D -m 644 "$src/$1" "$dest"
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
	sudo systemctl start systemd-zram-setup@zram0.service
	sudo sysctl --quiet --load "$root/etc/sysctl.d/99-zram.conf" 2>/dev/null || true
	sudo systemctl enable --now systemd-oomd.service
}

libvirt() {
	# The daemons (per-driver sockets on Arch and Fedora, the monolithic libvirtd on Debian/Ubuntu),
	# the NAT network VMs get their IP from, and access for this user
	if systemctl list-unit-files virtqemud.socket >/dev/null 2>&1; then
		sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket
	else
		sudo systemctl enable --now libvirtd.socket
	fi
	sudo virsh -c qemu:///system net-autostart default >/dev/null
	sudo virsh -c qemu:///system net-start default >/dev/null 2>&1 || true # already active is fine
	if ! id -nG "$USER" | tr ' ' '\n' | grep -qx libvirt; then
		sudo usermod -aG libvirt "$USER"
		log_warn relogin msg='added to the libvirt group; takes effect at the next login'
	fi
	changed=1
}

case ${1:-} in
memory) memory ;;
libvirt) libvirt ;;
*) echo 'usage: system.sh memory|libvirt' >&2 && exit 2 ;;
esac
if ((changed)); then log_info system part="$1"; else echo "$1: already in place"; fi
