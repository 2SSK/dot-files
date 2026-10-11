#!/usr/bin/env bash
# Claude Code where the distro doesn't ship it: the pinned npm release in ~/.local.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
npm_global @anthropic-ai/claude-code 2.1.293 claude
