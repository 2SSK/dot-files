#!/usr/bin/env bash
# uv and uvx (Python tools; the Grafana MCP server runs through uvx) where the distro doesn't ship
# them: pinned static release into ~/.local/bin.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

version=0.12.23
sha256=1cff8783850e794470aadb73f54b749542a511fc57b0ce6468b64bd3852e0ade
bin="$HOME/.local/bin"

[[ -x $bin/uvx && $("$bin/uv" --version 2>/dev/null) == *" $version"* ]] && exit 0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/uv.tar.gz" \
	"https://github.com/astral-sh/uv/releases/download/$version/uv-x86_64-unknown-linux-musl.tar.gz"
echo "$sha256  $tmp/uv.tar.gz" | sha256sum -c --quiet
tar -xzf "$tmp/uv.tar.gz" -C "$tmp" --strip-components=1
install -D -m 755 "$tmp/uv" "$bin/uv"
install -D -m 755 "$tmp/uvx" "$bin/uvx"
log_info installed name=uv version="$version" path="$bin/uv"
