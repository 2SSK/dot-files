#!/usr/bin/env bash
# System-level setup (sudo): the memory safety net, libvirt, docker, the GRUB theme and the login screen. Installs
# the tracked files under system/ into / and enables services; a no-op when everything is already
# in place.
# usage: system.sh memory|libvirt|docker|grub|sddm
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"
((EUID != 0)) || die run_as_user msg='run it as your user: it reads your theme and calls sudo itself'
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
	# The daemons (per-driver sockets on Arch and Fedora, the monolithic libvirtd on Debian/Ubuntu)
	local unit units=(libvirtd.socket)
	systemctl list-unit-files virtqemud.socket >/dev/null 2>&1 &&
		units=(virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket)
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
	sudo systemctl enable --now docker.socket
	if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
		sudo usermod -aG docker "$USER"
		log_warn relogin msg='added to the docker group; takes effect at the next login'
	fi
	changed=1
}

grub_set() { # <KEY> <value>: set a line in /etc/default/grub
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

grub_theme() { # a minimal theme from the desktop palette, rebuilt on every run
	local palette="${XDG_STATE_HOME:-$HOME/.local/state}/desktop/theme/palette.json"
	[[ -f $palette ]] || die no_theme msg='run: theme set <family>'
	local boot=/boot/grub mkfont=grub-mkfont
	[[ -d $root/boot/grub2 ]] && boot=/boot/grub2 mkfont=grub2-mkfont
	local dest="$root$boot/themes/desktop" tmp
	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064 # expand now: tmp is local
	trap "rm -rf '$tmp'" RETURN

	local bg fg muted surface
	read -r bg fg muted surface < <(jq -r '.ui | "\(.bg) \(.fg) \(.fg_muted) \(.surface)"' "$palette")
	local glyphs=0x20-0x7E,0xA0-0x17F,0x2190-0x2193,0x2022-0x2022
	font() { # <pattern> <size> <out> <family>: prints the name GRUB knows the font by
		local match
		match="$(fc-match -f '%{file}:%{index}' "$1")"
		"$mkfont" -n "$4" -i "${match##*:}" -s "$2" -r "$glyphs" -o "$tmp/$3" "${match%:*}" 2>/dev/null ||
			die grub_font font="${match%:*}"
		# the name is the NAME section of the PFF2 file: family, style ("Regular", "Book"...), size
		python3 -c 'import sys; d = open(sys.argv[1], "rb").read(); i = d.index(b"NAME") + 4
n = int.from_bytes(d[i:i + 4], "big"); print(d[i + 4:i + 4 + n].split(b"\\0")[0].decode())' "$tmp/$3"
	}
	local menu_font hint_font term_font
	menu_font="$(font 'Inter:style=Regular' 26 menu.pf2 Desktop)" || exit 1
	hint_font="$(font 'Inter:style=Regular' 16 hint.pf2 DesktopHint)" || exit 1
	term_font="$(font monospace 16 term.pf2 DesktopMono)" || exit 1

	# Selected entry: a rounded pill cut into GRUB's nine pieces (8-bit RGBA, the only PNG GRUB reads)
	local i pieces=(nw n ne w c e sw s se)
	magick -size 42x42 xc:none -fill "$surface" -draw 'roundrectangle 0,0 41,41 14,14' \
		-crop 14x14 +repage -strip "PNG32:$tmp/select_%d.png"
	for i in "${!pieces[@]}"; do mv "$tmp/select_$i.png" "$tmp/select_${pieces[i]}.png"; done

	cat >"$tmp/theme.txt" <<-EOF
		# Generated by system.sh grub from the desktop palette
		title-text: ""
		desktop-color: "$bg"
		terminal-font: "$term_font"

		+ boot_menu {
		  left = 35%
		  top = 36%
		  width = 30%
		  height = 40%
		  item_font = "$menu_font"
		  item_color = "$muted"
		  selected_item_color = "$fg"
		  selected_item_pixmap_style = "select_*.png"
		  item_height = 56
		  item_padding = 24
		  item_spacing = 12
		  icon_width = 0
		  scrollbar = false
		}

		+ label {
		  id = "__timeout__"
		  left = 0
		  top = 100%-80
		  width = 100%
		  align = "center"
		  font = "$hint_font"
		  color = "$muted"
		  text = "Booting in %d s   •   ↑↓ select   •   e edit   •   c console"
		}
	EOF

	local f
	for f in "$tmp"/*; do
		cmp -s "$f" "$dest/${f##*/}" 2>/dev/null && continue
		sudo install -D -m 644 "$f" "$dest/${f##*/}"
		changed=1
	done
	for f in "$dest"/*; do # files an older version of the theme left behind
		[[ -e $f && ! -e $tmp/${f##*/} ]] || continue
		sudo rm "$f"
		changed=1
	done

	grub_set GRUB_THEME "\"$boot/themes/desktop/theme.txt\""
	# The theme needs graphical output; a serial console (servers, cloud images) is left alone
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
	((changed)) || return 0
	if command -v update-grub >/dev/null; then
		sudo update-grub
	elif command -v grub2-mkconfig >/dev/null; then
		sudo grub2-mkconfig -o "$root$boot/grub.cfg"
	else
		sudo grub-mkconfig -o "$root$boot/grub.cfg"
	fi
}

install_if_changed() { # <file> <destination>: install as root when missing or different
	cmp -s "$1" "$2" 2>/dev/null && return 0
	sudo install -D -m 644 "$1" "$2"
	changed=1
}

sddm_theme() { # the login screen in the desktop theme; run again after theme set to follow it
	local state="${XDG_STATE_HOME:-$HOME/.local/state}/desktop" dir=usr/share/sddm/themes/desktop
	[[ -f $state/theme/sddm-theme.conf ]] || die no_theme msg='run: theme set <family>'
	put $dir/Main.qml
	put $dir/metadata.desktop
	install_if_changed "$state/theme/sddm-theme.conf" "$root/$dir/theme.conf"

	# sddm can't read the home directory: a copy of the wallpaper, at most 2560 px wide
	local wallpaper tmp
	wallpaper="$(readlink -f "$state/wallpaper" 2>/dev/null || true)"
	[[ -f $wallpaper ]] || wallpaper="$here/../.local/share/desktop/wallpapers/cat-mocha-lavender_19.jpg"
	tmp="$(mktemp --suffix=.jpg)"
	# shellcheck disable=SC2064 # expand now: tmp is local
	trap "rm -f '$tmp'" RETURN
	magick "$wallpaper" -resize '2560x2560>' -strip -quality 90 "$tmp"
	install_if_changed "$tmp" "$root/$dir/background.jpg"

	# /etc/sddm.conf overrides sddm.conf.d, so a Current= there is changed in place (original kept)
	local conf="$root/etc/sddm.conf"
	if grep -q '^Current=' "$conf" 2>/dev/null; then
		if ! grep -qx 'Current=desktop' "$conf"; then
			[[ -e $conf.pre-desktop ]] || sudo cp "$conf" "$conf.pre-desktop"
			sudo sed -i 's|^Current=.*|Current=desktop|' "$conf"
			changed=1
		fi
	else
		printf '[Theme]\nCurrent=desktop\n' >"$tmp.conf"
		install_if_changed "$tmp.conf" "$root/etc/sddm.conf.d/10-desktop.conf"
		rm -f "$tmp.conf"
	fi
}

case ${1:-} in
memory) memory ;;
libvirt) libvirt ;;
docker) docker_daemon ;;
grub) grub_theme ;;
sddm) sddm_theme ;;
*) echo 'usage: system.sh memory|libvirt|docker|grub|sddm' >&2 && exit 2 ;;
esac
if ((changed)); then log_info system part="$1"; else echo "$1: already in place"; fi
