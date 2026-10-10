#!/usr/bin/env bash
# autotiling (i3 and sway split the other way at each new window) where the distro has no package:
# from PyPI with pipx, pinned.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=1.9.3 # the newest on PyPI (GitHub tags run ahead)
command -v autotiling >/dev/null && exit 0
command -v pipx >/dev/null || case "$(distro)" in
	debian) sudo apt-get install -y pipx ;;
	fedora) sudo dnf install -y pipx ;;
esac
pipx install --quiet "autotiling==$version"
log_info installed name=autotiling version="$version"
