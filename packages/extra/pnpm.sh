#!/usr/bin/env bash
# pnpm where the distro doesn't ship it: pinned standalone release (bundles its own node) into
# ~/.local/share/pnpm, linked from ~/.local/bin.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

version=12.10.1
sha256=502a275984a4cd01e5579ac72049a241091cac5118e44becf84951130c3e079e
dir="$HOME/.local/share/pnpm/$version"
bin="$HOME/.local/bin/pnpm"

[[ -x $dir/pnpm && $(readlink "$bin") == "$dir/pnpm" ]] && exit 0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/pnpm.tar.gz" "https://github.com/pnpm/pnpm/releases/download/v$version/pnpm-linux-x64.tar.gz"
echo "$sha256  $tmp/pnpm.tar.gz" | sha256sum -c --quiet
mkdir -p "$dir" "${bin%/*}"
tar -xzf "$tmp/pnpm.tar.gz" -C "$dir"
ln -sfn "$dir/pnpm" "$bin"
log_info installed name=pnpm version="$version" path="$bin"
