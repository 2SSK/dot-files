#!/usr/bin/env bash
# adb-mcp (github.com/iksnerd/adb-mcp), the MCP server for Android devices, emulators and Waydroid:
# pinned release, its sha256 checked, not the README's curl | sh.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.25.0
[[ $("$bin/adb-mcp" version 2>/dev/null) == *"$version"* ]] && exit 0
install_release "https://github.com/iksnerd/adb-mcp/releases/download/v$version/adb-mcp_v${version}_linux_amd64.gz" \
	5bb92c916167fbdeecabef001e49a797c9ea7c37b1b73e2d6d9a410b55e9080a adb-mcp
log_info installed name=adb-mcp version="$version" path="$bin/adb-mcp"
