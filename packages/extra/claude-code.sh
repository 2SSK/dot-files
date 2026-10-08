#!/usr/bin/env bash
# Claude Code where the distro doesn't ship it: the pinned npm release in ~/.local (npm checks its
# integrity), so no root is needed.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

package=@anthropic-ai/claude-code
version=2.1.293
prefix="$HOME/.local"

[[ $("$prefix/bin/claude" --version 2>/dev/null) == *"$version"* ]] && exit 0
# its postinstall fetches the native binary, so allow this package's scripts (npm blocks them)
npm install -g --prefix "$prefix" --no-fund --no-audit --allow-scripts="$package" "$package@$version" >/dev/null
log_info installed name=claude-code version="$version" path="$prefix/bin/claude"
