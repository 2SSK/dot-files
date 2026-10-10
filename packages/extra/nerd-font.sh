#!/usr/bin/env bash
# JetBrains Mono Nerd Font where the distro has none: pinned release into ~/.local/share/fonts.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=3.5.1
dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
[[ -f $dir/.version && $(cat "$dir/.version") == "$version" ]] && exit 0
f="$(fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/JetBrainsMono.tar.xz" 04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf)"
mkdir -p "$dir"
tar -xJf "$f" -C "$dir" --wildcards "*.ttf"
echo "$version" >"$dir/.version"
fc-cache -f "$dir" >/dev/null
log_info installed name=nerd-font version="$version"
