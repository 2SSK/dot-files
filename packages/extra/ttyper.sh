#!/usr/bin/env bash
# ttyper (typing test) where the distro doesn't ship it: pinned static release into ~/.local/bin.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

version=1.6.0
sha256=0697132e20c64e5b764b2133f205aba17aea2580935892a2037a0fae875eac90
bin="$HOME/.local/bin/ttyper"

[[ -x $bin && $("$bin" --version 2>/dev/null) == *"$version"* ]] && exit 0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/ttyper.tar.gz" \
	"https://github.com/max-niederman/ttyper/releases/download/v$version/ttyper-x86_64-unknown-linux-musl.tar.gz"
echo "$sha256  $tmp/ttyper.tar.gz" | sha256sum -c --quiet
tar -xzf "$tmp/ttyper.tar.gz" -C "$tmp"
install -D -m 755 "$tmp/ttyper" "$bin"
log_info installed name=ttyper version="$version" path="$bin"
