#!/usr/bin/env bash
# temporal-mcp (github.com/temporalio/temporal-mcp), Temporal's MCP server: pinned release, its
# sha256 checked, not the README's curl | sh.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.0.6
[[ $("$bin/temporal-mcp" --version 2>/dev/null) == *"$version"* ]] && exit 0
install_release "https://github.com/temporalio/temporal-mcp/releases/download/v$version/temporal-mcp_${version}_linux_amd64.tar.gz" \
	c4e84771c6969da0f61f19a28e86c9011659d088eca118209c08b159641ff211 temporal-mcp
log_info installed name=temporal-mcp version="$version" path="$bin/temporal-mcp"
