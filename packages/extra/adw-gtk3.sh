#!/usr/bin/env bash
# adw-gtk3 (GTK 3 apps in the libadwaita look) where the distro has none: pinned release into
# ~/.local/share/themes.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=6.5
dir="$HOME/.local/share/themes"
[[ -f $dir/adw-gtk3/.version && $(cat "$dir/adw-gtk3/.version") == "$version" ]] && exit 0
f="$(fetch "https://github.com/lassekongo83/adw-gtk3/releases/download/v$version/adw-gtk3v$version.tar.xz" a81780fadfc432be0fc3d89c4ebb41aa28e4f032d42c36f9789c57dd10cfa41c)"
mkdir -p "$dir"
tar -xJf "$f" -C "$dir"
echo "$version" >"$dir/adw-gtk3/.version"
log_info installed name=adw-gtk3 version="$version"
