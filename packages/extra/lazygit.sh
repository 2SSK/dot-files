#!/usr/bin/env bash
# lazygit where the distro has none: pinned release.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.66.0
[[ $("$bin/lazygit" --version 2>/dev/null) == *"version=$version"* ]] && exit 0
f="$(fetch "https://github.com/jesseduffield/lazygit/releases/download/v$version/lazygit_${version}_linux_x86_64.tar.gz" 5b45541155d20bd32bf2cc5ab5b7e3d91c2eebf0fb1242281350edc27d59d2b7)"
tar -xzf "$f" -C "$tmp" lazygit
install -D -m 755 "$tmp/lazygit" "$bin/lazygit"
log_info installed name=lazygit version="$version"
