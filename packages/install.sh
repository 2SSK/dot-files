#!/usr/bin/env bash
# Install package layers for this distro. Safe to re-run: every step skips what is already installed.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"

layers_all=(base cli x11 wayland dev)
layers_default=(base cli x11 wayland)

usage() {
	printf 'usage: install.sh [--dry-run] [layer...] | --distro\nlayers: %s (default: %s); list format: see base.txt\n' \
		"${layers_all[*]}" "${layers_default[*]}"
}

detect_distro() {
	local ID='' ID_LIKE='' id
	# shellcheck source=/dev/null
	source "${OS_RELEASE:-/etc/os-release}"
	for id in $ID $ID_LIKE; do
		case $id in
		arch | debian | fedora) echo "$id" && return ;;
		ubuntu) echo debian && return ;;
		esac
	done
	log_error unsupported_distro id="$ID" id_like="$ID_LIKE"
	exit 3
}

column() { # <distro> <layer>
	local col
	case $1 in arch) col=1 ;; debian) col=2 ;; fedora) col=3 ;; esac
	awk -v c="$col" '{ sub(/#.*/, "") } NF { print $c }' "$here/$2.txt"
}

install_native() { # <distro> <pkg...>
	local distro=$1
	shift
	case $distro in
	# Arch supports installs only together with a full upgrade: -S alone fails on a stale
	# database (404 for replaced versions), -Sy alone risks a partial upgrade
	arch) sudo pacman -Syu --needed --noconfirm "$@" ;;
	debian) sudo apt-get update && sudo apt-get install -y "$@" ;;
	fedora) sudo dnf install -y "$@" ;;
	esac
}

install_aur() { # <pkg...>
	if ! command -v yay >/dev/null; then
		log_info bootstrap_yay
		sudo pacman -S --needed --noconfirm base-devel git
		local tmp
		tmp="$(mktemp -d)"
		git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp"
		(cd "$tmp" && makepkg -si --noconfirm)
		rm -rf "$tmp"
	fi
	# AUR forks replace repo packages (i3lock-color → i3lock, swayfx → sway); --noconfirm
	# declines that swap, so remove installed conflicts first. -dd: the fork provides them.
	local c old=()
	for c in $(yay -Si --aur "$@" | awk -F' : ' '/^Conflicts With/ && $2 != "None" { print $2 }'); do
		c=${c%%[<>=]*}
		[[ " $* " != *" $c "* && $(pacman -Qq "$c" 2>/dev/null) == "$c" ]] && old+=("$c")
	done
	((${#old[@]} == 0)) || sudo pacman -Rdd --noconfirm "${old[@]}"
	yay -S --needed --noconfirm "$@"
}

main() {
	local dry_run=0 layers=()
	while (($#)); do
		case $1 in
		-h | --help) usage && exit 0 ;;
		--dry-run) dry_run=1 ;;
		--distro) detect_distro && exit 0 ;;
		*)
			[[ " ${layers_all[*]} " == *" $1 "* ]] || { usage >&2 && exit 2; }
			layers+=("$1")
			;;
		esac
		shift
	done
	((${#layers[@]})) || layers=("${layers_default[@]}")
	((dry_run || EUID != 0)) || die run_as_root msg='run as your user; sudo is used where needed'

	local distro
	distro="$(detect_distro)"

	local -a native=() aur=() extra=()
	local -A seen=()
	local layer entry
	for layer in "${layers[@]}"; do
		while read -r entry; do
			[[ $entry == - || -n ${seen[$entry]:-} ]] && continue
			seen[$entry]=1
			case $entry in
			aur:*) aur+=("${entry#aur:}") ;;
			@*) extra+=("${entry#@}") ;;
			*) native+=("$entry") ;;
			esac
		done < <(column "$distro" "$layer")
	done

	if ((dry_run)); then
		((${#native[@]} == 0)) || echo "native: ${native[*]}"
		((${#aur[@]} == 0)) || echo "aur: ${aur[*]}"
		((${#extra[@]} == 0)) || echo "extra: ${extra[*]}"
		return
	fi

	log_info install distro="$distro" layers="${layers[*]}"
	((${#native[@]} == 0)) || install_native "$distro" "${native[@]}"
	((${#aur[@]} == 0)) || install_aur "${aur[@]}"

	# packages/extra/<name>.sh installs what the distro doesn't ship; each must be idempotent
	local name missing=()
	for name in "${extra[@]}"; do
		if [[ -x $here/extra/$name.sh ]]; then
			"$here/extra/$name.sh"
		else
			missing+=("$name")
		fi
	done
	((${#missing[@]} == 0)) || { log_error extra_missing names="${missing[*]}" && exit 3; }
	log_info installed distro="$distro"
}

main "$@"
