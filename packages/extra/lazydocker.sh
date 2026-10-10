#!/usr/bin/env bash
# lazydocker where the distro has none: pinned release.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.25.2
[[ $("$bin/lazydocker" --version 2>/dev/null) == *"$version"* ]] && exit 0
f="$(fetch "https://github.com/jesseduffield/lazydocker/releases/download/v$version/lazydocker_${version}_Linux_x86_64.tar.gz" 0d9dbfc26068b218e7ed84b104748cadc6e3cf733c0afd35465306fb39b9523c)"
tar -xzf "$f" -C "$tmp" lazydocker
install -D -m 755 "$tmp/lazydocker" "$bin/lazydocker"
log_info installed name=lazydocker version="$version"
