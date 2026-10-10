#!/usr/bin/env bash
# rmpc, the music player (mpd client), where the distro has none: pinned static release.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.11.0
[[ $("$bin/rmpc" --version 2>/dev/null) == *"$version"* ]] && exit 0
f="$(fetch "https://github.com/mierak/rmpc/releases/download/v$version/rmpc-v$version-x86_64-unknown-linux-musl.tar.gz" 9cef6597d14ae58336ab465056da9e313d3b3bb3986c67691ee6ae13b7bf5a74)"
tar -xzf "$f" -C "$tmp"
install -D -m 755 "$tmp/rmpc" "$bin/rmpc"
log_info installed name=rmpc version="$version"
