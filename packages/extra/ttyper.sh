#!/usr/bin/env bash
# ttyper (typing test) where the distro doesn't ship it: pinned static release into ~/.local/bin.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=1.6.0
[[ $("$bin/ttyper" --version 2>/dev/null) == *"$version"* ]] && exit 0
install_release "https://github.com/max-niederman/ttyper/releases/download/v$version/ttyper-x86_64-unknown-linux-musl.tar.gz" \
	0697132e20c64e5b764b2133f205aba17aea2580935892a2037a0fae875eac90 ttyper
log_info installed name=ttyper version="$version" path="$bin/ttyper"
