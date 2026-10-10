#!/usr/bin/env bash
# yazi (and ya), the terminal file manager, where the distro has none: pinned static release.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=26.9.1
[[ $("$bin/yazi" --version 2>/dev/null) == *"$version"* ]] && exit 0
f="$(fetch "https://github.com/sxyazi/yazi/releases/download/v$version/yazi-x86_64-unknown-linux-musl.zip" 9b9c39decccf8cb0ff53a7d637d38f8a79d93bbd0099f4ea9c619ef6bb392f5d)"
unzip -q -o "$f" -d "$tmp"
install -D -m 755 "$tmp/yazi-x86_64-unknown-linux-musl/yazi" "$bin/yazi"
install -D -m 755 "$tmp/yazi-x86_64-unknown-linux-musl/ya" "$bin/ya"
log_info installed name=yazi version="$version"
