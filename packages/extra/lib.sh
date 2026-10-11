# shellcheck shell=bash
# Shared by packages/extra/*.sh: a pinned download, checked against its sha256, into a temp folder
# that goes when the script ends; a release's binaries into ~/.local/bin; an npm release into
# ~/.local; a Fedora COPR. Sourced; the script sets -euo pipefail itself.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

# shellcheck disable=SC2034 # for the scripts that source this
bin="$HOME/.local/bin"
# on disk, not /tmp: /tmp is often RAM (tmpfs), too small for a build
cache="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$cache"
tmp="$(mktemp -d -p "$cache" dot-files-build.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

fetch() { # <url> <sha256>: downloads into $tmp, prints the file's path
	local out="$tmp/${1##*/}"
	curl -fsSL --retry 3 -o "$out" "$1"
	echo "$2  $out" | sha256sum -c --quiet >&2
	echo "$out"
}

distro() { # arch or fedora (as install.sh decides)
	"$here/../install.sh" --distro
}

install_release() { # <url> <sha256> <file in the archive>...: those files into ~/.local/bin
	local f file
	f="$(fetch "$1" "$2")"
	case $f in
	*.tar.gz | *.tgz) tar -xzf "$f" -C "$tmp" ;;
	*.zip) unzip -q -o "$f" -d "$tmp" ;;
	*.gz) gunzip -c "$f" >"$tmp/${3##*/}" ;; # a single compressed binary
	esac
	for file in "${@:3}"; do install -D -m 755 "$tmp/$file" "$bin/${file##*/}"; done
}

# <package> <version> <command>: the pinned npm release in ~/.local (npm checks its integrity, no
# root needed). Its own install scripts may run: they fetch the native binary (npm blocks them).
npm_global() {
	[[ $("$HOME/.local/bin/$3" --version 2>/dev/null) == *"$2"* ]] && return 0
	npm install -g --prefix "$HOME/.local" --no-fund --no-audit --allow-scripts="$1" "$1@$2" >/dev/null
	log_info installed name="$3" version="$2" path="$HOME/.local/bin/$3"
}

copr_install() { # <copr> <dnf install arguments...>: Fedora, from a COPR (dnf's copr plugin first)
	sudo dnf install -y dnf5-plugins >/dev/null 2>&1 || sudo dnf install -y dnf-plugins-core
	sudo dnf copr enable -y "$1"
	sudo dnf install -y "${@:2}"
}
