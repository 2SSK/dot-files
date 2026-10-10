#!/usr/bin/env bash
# SwayFX. On Arch, built from its AUR recipe against the repo's scenefx. scenefx 0.5 moved from the
# AUR (scenefx0.5, now deleted) into extra (scenefx), but the recipe still depends on the AUR name,
# so yay can't resolve it. Once the recipe names scenefx, the rename below changes nothing.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/../.. source=.local/lib/desktop/log.sh
source "$here/../../.local/lib/desktop/log.sh"

# Fedora: the swayfx project's COPR.
if command -v dnf >/dev/null; then
	rpm -q swayfx >/dev/null 2>&1 && exit 0
	sudo dnf install -y dnf5-plugins >/dev/null 2>&1 || sudo dnf install -y dnf-plugins-core
	sudo dnf copr enable -y swayfx/swayfx
	sudo dnf install -y --allowerasing swayfx
	log_info installed name=swayfx via=copr
	exit 0
fi
pacman -Qq swayfx >/dev/null 2>&1 && exit 0

sudo pacman -S --needed --noconfirm base-devel git scenefx
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone --quiet --depth 1 https://aur.archlinux.org/swayfx.git "$tmp"
sed -i 's/"scenefx0\.5"/"scenefx"/' "$tmp/PKGBUILD"
# swayfx replaces sway, and makepkg's --noconfirm would decline that swap
if pacman -Qq sway >/dev/null 2>&1; then sudo pacman -Rdd --noconfirm sway; fi
(cd "$tmp" && makepkg -si --noconfirm)
log_info built name=swayfx
