#!/usr/bin/env bash
# pnpm where the distro doesn't ship it: pinned standalone release (bundles its own node) into
# ~/.local/share/pnpm, linked from ~/.local/bin.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

version=12.10.1
sha256=502a275984a4cd01e5579ac72049a241091cac5118e44becf84951130c3e079e
dir="$HOME/.local/share/pnpm/$version"
link="$bin/pnpm"

[[ -x $dir/pnpm && $(readlink "$link") == "$dir/pnpm" ]] && exit 0
f="$(fetch "https://github.com/pnpm/pnpm/releases/download/v$version/pnpm-linux-x64.tar.gz" "$sha256")"
mkdir -p "$dir" "$bin"
tar -xzf "$f" -C "$dir"
ln -sfn "$dir/pnpm" "$link"
log_info installed name=pnpm version="$version" path="$link"
