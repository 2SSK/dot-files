# shellcheck shell=bash
# Shared by packages/extra/*.sh: a pinned download, checked against its sha256, into a temp folder
# that goes when the script ends. Sourced; the script sets -euo pipefail itself.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

# shellcheck disable=SC2034 # for the scripts that source this
bin="$HOME/.local/bin"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fetch() { # <url> <sha256>: downloads into $tmp, prints the file's path
	local out="$tmp/${1##*/}"
	curl -fsSL --retry 3 -o "$out" "$1"
	echo "$2  $out" | sha256sum -c --quiet >&2
	echo "$out"
}

distro() { # arch, debian or fedora (as install.sh decides)
	"$here/../install.sh" --distro
}
