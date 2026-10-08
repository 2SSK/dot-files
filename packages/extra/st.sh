#!/usr/bin/env bash
# st (backup terminal on X11): pinned release + the xresources-with-reload-signal patch, installed
# into ~/.local. Font, padding and colours come from ~/.Xresources, so the build itself stays stock.
# Rebuilds only when the version, the patch or this script changes.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

version=0.9.3
sha256=9ed9feabcded713d4ded38c8cebf36a3b08f0042ef7934a0e2b2409da56e649b
patch="$here/st-xresources-reload.diff" # https://st.suckless.org/patches/xresources-with-reload-signal/
prefix="$HOME/.local"
stamp="${XDG_STATE_HOME:-$HOME/.local/state}/desktop/st.build"

want="$version $(cat "${BASH_SOURCE[0]}" "$patch" | sha256sum | cut -d' ' -f1)"
if [[ -x $prefix/bin/st && $(cat "$stamp" 2>/dev/null) == "$want" ]]; then
	exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/st.tar.gz" "https://dl.suckless.org/st/st-$version.tar.gz"
echo "$sha256  $tmp/st.tar.gz" | sha256sum -c --quiet
tar -xzf "$tmp/st.tar.gz" -C "$tmp"
cd "$tmp/st-$version"
patch -p1 --quiet <"$patch"
make install PREFIX="$prefix" >/dev/null # also compiles st's terminfo into ~/.terminfo

mkdir -p "${stamp%/*}"
echo "$want" >"$stamp"
log_info built name=st version="$version" path="$prefix/bin/st"
