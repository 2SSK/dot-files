#!/usr/bin/env bash
# Makes room and keeps the system lean (Arch). Every removal goes through pacman's or Docker's own
# listing first; pacman asks before it removes anything.
#   packages  what packages/remove.txt names (with what only they needed), then orphans; the
#             packages the repo's lists name are marked explicit first, so none goes as a dependency
#   docker    stopped containers, images no container uses, the build cache and unnamed volumes
#             (named ones, a database's say, stay)
#   caches    pacman's package cache (the last 2 versions of what is installed), the AUR build cache
#   all       all three
# usage: cleanup.sh packages|docker|caches|all
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"
((EUID != 0)) || die run_as_user msg='run it as your user: it calls sudo itself'

listed() { # <file>...: the package names in the files, one per line (comments and blanks left out)
	grep -hvE '^[[:space:]]*(#|$)' "$@" | awk '{ print $1 }'
}

repo_packages() { # the arch column of the install lists, without the aur: and @ (built here) marks
	awk '!/^#/ && NF { n = $1; sub(/^(aur:|@)/, "", n); if (n != "-") print n }' "$here"/*.txt
}

installed() { # names on stdin that are installed
	local name
	while read -r name; do
		pacman -Qq "$name" >/dev/null 2>&1 && echo "$name"
	done
}

packages() {
	local keep remove orphans
	# what the repo installs stays, even where it came in as another package's dependency
	mapfile -t keep < <(repo_packages | grep -vxF -f <(listed "$here/remove.txt") | installed)
	((${#keep[@]} == 0)) || sudo pacman -D --asexplicit "${keep[@]}" >/dev/null
	# a service whose package goes is stopped first (auto-cpufreq: TLP manages power)
	if systemctl is-enabled --quiet auto-cpufreq.service 2>/dev/null; then
		sudo systemctl disable --now auto-cpufreq.service
	fi
	mapfile -t remove < <(listed "$here/remove.txt" | installed)
	if ((${#remove[@]})); then
		log_info removing count="${#remove[@]}"
		sudo pacman -Rns "${remove[@]}"
	fi
	mapfile -t orphans < <(pacman -Qdtq || true)
	if ((${#orphans[@]})); then
		log_info orphans count="${#orphans[@]}"
		sudo pacman -Rns "${orphans[@]}"
	fi
	# cmatrix 2.0 paints black behind the rain; the git build draws on the terminal's background
	if pacman -Qq cmatrix >/dev/null 2>&1 && ! pacman -Qq cmatrix-git >/dev/null 2>&1 && command -v yay >/dev/null; then
		yay -S cmatrix-git
	fi
}

docker_clean() {
	command -v docker >/dev/null || { echo "docker: not installed" && return 0; }
	docker system df
	docker container prune -f
	docker image prune -a -f
	docker builder prune -a -f
	docker volume prune -f # unnamed volumes only (-a would take named ones too)
	docker system df
}

caches() {
	if command -v paccache >/dev/null; then
		sudo paccache -r -k 2  # the last 2 versions of each installed package
		sudo paccache -r -u -k 0 # nothing of uninstalled ones
	fi
	if command -v yay >/dev/null; then
		yay -Sc --aur # asks: the AUR build folders of packages no longer installed, then all
	fi
}

case ${1:-} in
packages) packages ;;
docker) docker_clean ;;
caches) caches ;;
all) packages && docker_clean && caches ;;
*) echo 'usage: cleanup.sh packages|docker|caches|all' >&2 && exit 2 ;;
esac
