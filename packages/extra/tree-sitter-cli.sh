#!/usr/bin/env bash
# tree-sitter (nvim-treesitter builds parsers with it) where the distro has none: pinned release.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.27.1
[[ $("$bin/tree-sitter" --version 2>/dev/null) == *"$version"* ]] && exit 0
f="$(fetch "https://github.com/tree-sitter/tree-sitter/releases/download/v$version/tree-sitter-linux-x64.gz" d01042f94ba3d6827ddc9788e235f75d8366431be42bdf90ade534d960c98b7d)"
gunzip -c "$f" >"$tmp/tree-sitter"
install -D -m 755 "$tmp/tree-sitter" "$bin/tree-sitter"
log_info installed name=tree-sitter version="$version"
