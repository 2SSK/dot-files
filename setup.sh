#!/usr/bin/env bash
# Set up this machine from the repo: packages, submodules, stow into $HOME, login shell.
# Asks first, changes nothing until confirmed, and is safe to re-run.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source-path=SCRIPTDIR source=.local/lib/desktop/ui.sh
source "$repo/.local/lib/desktop/ui.sh"

usage() {
	cat <<EOF
usage: setup.sh [-y] [--wm both|i3|sway] [--dev] [--no-packages]

  -y, --yes       accept the defaults without asking (both WMs, back up existing configs)
  --wm WM         window manager(s) to install packages for
  --dev           also install the development tools
  --no-packages   skip packages and shell plugins
EOF
}

assume_yes=0

confirm() { # <question> <default y|n>
	local reply hint='y/N'
	[[ $2 == y ]] && hint='Y/n'
	if ((assume_yes)); then [[ $2 == y ]] && return 0 || return 1; fi
	read -rp "${cyan}?${reset} $1 ${dim}[$hint]${reset} " reply
	[[ ${reply:-$2} == [yY]* ]]
}

choose() { # <question> <option...>; first option is the default, prints the choice
	local q=$1 reply i
	shift
	if ((assume_yes)); then echo "${1%% *}" && return; fi
	printf '%s?%s %s\n' "$cyan" "$reset" "$q" >&2
	for i in $(seq $#); do printf '  %s%d)%s %s\n' "$bold" "$i" "$reset" "${!i}" >&2; done
	while read -rp "  choice ${dim}[1]${reset} " reply; do
		reply=${reply:-1}
		[[ $reply =~ ^[0-9]+$ ]] && ((reply >= 1 && reply <= $#)) && echo "${!reply%% *}" && return
	done
	exit 1
}

# show_layer <label> <layer>: every package of a layer for this distro, wrapped under a label.
# AUR packages are marked (aur), ones built from source (build).
show_layer() {
	local line
	printf '  %s%s%s\n' "$bold" "$1" "$reset"
	while IFS= read -r line; do
		printf '    %s%s%s\n' "$dim" "$line" "$reset"
	done < <("$repo/packages/install.sh" --dry-run "$2" |
		sed -E 's/^native: //; /^aur: /{s/^aur: //; s/([^ ]+)/\1(aur)/g}; /^extra: /{s/^extra: //; s/([^ ]+)/\1(build)/g}' |
		{ tr '\n' ' ' && echo; } | fold -s -w 76)
}

# Paths (relative to $HOME) where a real file or foreign link blocks a stow link.
conflicts() {
	(cd "$repo" && stow -n . 2>&1 || true) | sed -n 's/.* over existing target \(.*\) since .*/\1/p'
}

# stow -R keeps links to files that were deleted or newly ignored, so drop every
# link into the repo and let stow recreate the ones that still belong.
prune_links() {
	local link
	while IFS= read -r -d '' link; do
		if [[ $(readlink -m "$link") == "$repo"/* ]]; then rm "$link"; fi
	done < <( # links into the repo only exist where it has files: top-level dotfiles, .config, .local
		find "$HOME" -maxdepth 1 -type l -print0
		find "$HOME/.config" "$HOME/.local" -xdev -path "$repo" -prune -o -type l -print0 2>/dev/null
	)
}

# User services from the packages: mpd plays music, mpd-mpris exposes it to media keys and the bar.
enable_services() {
	local unit units=()
	systemctl --user show-environment >/dev/null 2>&1 || { warn 'no systemd user session; services not enabled' && return 0; }
	for unit in mpd.service mpd-mpris.service; do
		systemctl --user cat "$unit" >/dev/null 2>&1 && units+=("$unit")
	done
	((${#units[@]})) || return 0
	step 'Enabling user services'
	systemctl --user daemon-reload
	systemctl --user enable --now "${units[@]}"
	ok "running: ${units[*]}"
}

main() {
	local wm='' dev=0 packages=1
	while (($#)); do
		case $1 in
		-h | --help) usage && exit 0 ;;
		-y | --yes) assume_yes=1 ;;
		--wm)
			[[ ${2:-} =~ ^(both|i3|sway)$ ]] || { usage >&2 && exit 2; }
			wm=$2 && shift
			;;
		--dev) dev=1 ;;
		--no-packages) packages=0 ;;
		*) usage >&2 && exit 2 ;;
		esac
		shift
	done
	((EUID != 0)) || fail 'run as your user; sudo is used where needed'
	((assume_yes)) || [[ -t 0 ]] || fail 'not a terminal; pass -y to accept the defaults' 2

	printf '%sdesktop setup%s %s%s%s\n' "$bold" "$reset" "$dim" "$repo" "$reset"

	# --- Ask ---
	local -a found=()
	mapfile -t found < <(conflicts)
	local policy=none backup=''
	if ((${#found[@]})); then
		step "Existing configs that would be replaced (${#found[@]})"
		printf "  ${dim}~/%s${reset}\n" "${found[@]}"
		policy="$(choose 'What should happen to them?' 'backup  move them to ~/.local/state/desktop/backup' \
			'overwrite  delete them' 'abort')"
		[[ $policy != abort ]] || exit 0
		backup="${XDG_STATE_HOME:-$HOME/.local/state}/desktop/backup/$(date +%Y%m%d-%H%M%S)"
	fi

	local -a layers=()
	local distro='' vm=0 safety=0 docker=0
	if ((packages)); then
		distro="$("$repo/packages/install.sh" --distro)"
		step "Packages for $distro"
		show_layer 'base (always)' base
		layers=(base)
		[[ -n $wm ]] || wm="$(choose 'Window manager?' 'both  i3 (X11) and SwayFX (Wayland)' 'i3  X11 only' 'sway  Wayland only')"
		if [[ $wm != sway ]]; then show_layer 'x11 (i3)' x11 && layers+=(x11); fi
		if [[ $wm != i3 ]]; then show_layer 'wayland (SwayFX)' wayland && layers+=(wayland); fi
		show_layer 'cli (terminal tools)' cli
		if confirm 'Install the terminal tools?' y; then layers+=(cli); fi
		show_layer 'vm (virtual machines: libvirt, virt-manager)' vm
		if confirm 'Install the virtual machine tools?' y; then layers+=(vm) && vm=1; fi
		show_layer 'dev (go, gopls, clangd, pnpm, docker, lint and test tools)' dev
		if ((dev)) || confirm 'Install the development tools?' n; then layers+=(dev) && docker=1; fi
	fi

	if ((packages)); then
		printf '  %s%s%s\n' "$dim" 'zram compresses little-used memory instead of killing apps when RAM fills up;' "$reset"
		printf '  %s%s%s\n' "$dim" 'systemd-oomd stops only the runaway app before the desktop freezes.' "$reset"
		if confirm 'Turn on the memory safety net (zram + systemd-oomd)?' y; then safety=1; fi
	fi

	local shell=0
	if [[ $(getent passwd "$USER" | cut -d: -f7) != */zsh ]] && confirm 'Make zsh your login shell?' y; then shell=1; fi

	# --- Confirm ---
	step 'Plan'
	row 'Packages' "$( ((packages)) && echo "${layers[*]} + shell plugins" || echo skip)"
	[[ $distro != arch ]] || row '' 'includes a full system upgrade (pacman -Syu), as Arch requires'
	local system=()
	((safety)) && system+=('memory safety net (zram, systemd-oomd)')
	((vm)) && system+=('libvirt services, default network, firewall zone, libvirt group')
	((docker)) && system+=('docker service + docker group')
	((${#system[@]} == 0)) || row 'System (sudo)' "$(printf '%s; ' "${system[@]}" | sed 's/; $//')"
	row 'Existing files' "$(case $policy in none) echo none ;; backup) echo "${#found[@]} → $backup" ;; *) echo "${#found[@]} deleted" ;; esac)"
	row 'Stow' "$repo → $HOME"
	local family mode
	read -r family mode < <("$repo/.local/bin/theme" current)
	row 'Theme' "$family $mode"
	row 'Login shell' "$( ((shell)) && echo zsh || echo unchanged)"
	echo
	confirm 'Proceed?' y || exit 0

	# --- Apply ---
	if ((packages)); then
		step 'Installing packages'
		"$repo/packages/install.sh" "${layers[@]}"
		ok "installed: ${layers[*]}"
		step 'Installing shell plugins'
		"$repo/packages/plugins.sh"
		ok 'zsh and bash plugins at their pinned tags'
		enable_services
		if ((safety || vm || docker)); then
			step 'System'
			((safety == 0)) || "$repo/packages/system.sh" memory
			((vm == 0)) || "$repo/packages/system.sh" libvirt
			((docker == 0)) || "$repo/packages/system.sh" docker
			ok 'system configured'
		fi
	fi

	if [[ -f $repo/.gitmodules ]]; then
		step 'Updating submodules'
		git -C "$repo" submodule update --init --recursive
		ok 'submodules up to date'
	fi

	step 'Linking configs'
	local rel
	for rel in "${found[@]}"; do
		if [[ $policy == backup ]]; then
			mkdir -p "$backup/$(dirname "$rel")"
			mv "$HOME/$rel" "$backup/$rel"
		else
			rm -rf -- "${HOME:?}/$rel"
		fi
	done
	((${#found[@]} == 0)) || warn "$policy: ${#found[@]} existing file(s)"
	prune_links
	(cd "$repo" && stow .) # target and --no-folding come from .stowrc
	ok "stowed into $HOME"

	step 'Theme'
	if command -v python3 >/dev/null; then
		"$repo/.local/bin/theme" set "$family" --mode "$mode"
		ok "$family $mode (change it with: theme set <family>)"
	else
		warn 'python3 missing; theme not rendered'
	fi

	if ((shell)); then
		step 'Login shell'
		command -v zsh >/dev/null || fail 'zsh is not installed'
		sudo chsh -s "$(command -v zsh)" "$USER"
		ok 'zsh is your login shell (from next login)'
	fi

	printf '\n%s✓ Done.%s\n' "$green$bold" "$reset"
}

main "$@"
