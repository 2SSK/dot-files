#!/usr/bin/env bash
# opencode where the distro doesn't ship it: the pinned npm release in ~/.local.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
npm_global opencode-ai 1.18.35 opencode
