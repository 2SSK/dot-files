#!/usr/bin/env bash
# The Bibata Modern Ice cursor where the distro has none: pinned release into ~/.local/share/icons.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=2.0.7
dir="$HOME/.local/share/icons/Bibata-Modern-Ice"
[[ -f $dir/.version && $(cat "$dir/.version") == "$version" ]] && exit 0
f="$(fetch "https://github.com/ful1e5/Bibata_Cursor/releases/download/v$version/Bibata-Modern-Ice.tar.xz" a68cae60c4dc706350e194ebc91c5fe48bc7bc9d59e119555834a2a7ee5078ef)"
mkdir -p "${dir%/*}"
tar -xJf "$f" -C "${dir%/*}"
echo "$version" >"$dir/.version"
log_info installed name=bibata version="$version"
