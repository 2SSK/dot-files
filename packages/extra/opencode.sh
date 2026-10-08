#!/usr/bin/env bash
# opencode where the distro doesn't ship it: the pinned npm release in ~/.local (npm checks its
# integrity), so no root is needed.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

package=opencode-ai
version=1.18.35
prefix="$HOME/.local"

[[ $("$prefix/bin/opencode" --version 2>/dev/null) == *"$version"* ]] && exit 0
# its postinstall fetches the native binary, so allow this package's scripts (npm blocks them)
npm install -g --prefix "$prefix" --no-fund --no-audit --allow-scripts="$package" "$package@$version" >/dev/null
log_info installed name=opencode version="$version" path="$prefix/bin/opencode"
