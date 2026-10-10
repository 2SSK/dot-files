#!/usr/bin/env bash
# starship (the prompt) where the distro has none: pinned static release.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=1.26.0
[[ $("$bin/starship" --version 2>/dev/null) == *"$version"* ]] && exit 0
f="$(fetch "https://github.com/starship/starship/releases/download/v$version/starship-x86_64-unknown-linux-musl.tar.gz" b7c232b0e8249d8e55a40beb79c5c43a7d370f3f9408bd215deb0170daeaadf3)"
tar -xzf "$f" -C "$tmp"
install -D -m 755 "$tmp/starship" "$bin/starship"
log_info installed name=starship version="$version"
