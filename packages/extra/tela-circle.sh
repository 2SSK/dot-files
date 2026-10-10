#!/usr/bin/env bash
# The Tela circle icons (blue, dark and light) where the distro has none: a pinned release of the
# source, installed by its own script into ~/.local/share/icons.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=2026-07-07
dir="$HOME/.local/share/icons"
[[ -f $dir/Tela-circle-blue/.version && $(cat "$dir/Tela-circle-blue/.version") == "$version" ]] && exit 0
f="$(fetch "https://github.com/vinceliuice/Tela-circle-icon-theme/archive/refs/tags/$version.tar.gz" 0a8aee6e95f19ff96cc497d804c75e2af4271a5e6472c55891fb8ac5b099b59b)"
tar -xzf "$f" -C "$tmp"
(cd "$tmp/Tela-circle-icon-theme-$version" && ./install.sh -d "$dir" blue >/dev/null)
echo "$version" >"$dir/Tela-circle-blue/.version"
log_info installed name=tela-circle version="$version"
