#!/usr/bin/env bash
# SwayFX. On Arch, built from its AUR recipe against the repo's scenefx. scenefx 0.5 moved from the
# AUR (scenefx0.5, now deleted) into extra (scenefx), but the recipe still depends on the AUR name,
# so yay can't resolve it. Once the recipe names scenefx, the rename below changes nothing.
set -euo pipefail

# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Fedora: the swayfx project's COPR.
if command -v dnf >/dev/null; then
	rpm -q swayfx >/dev/null 2>&1 && exit 0
	copr_install swayfx/swayfx --allowerasing swayfx
	log_info installed name=swayfx via=copr
	exit 0
fi
pacman -Qq swayfx >/dev/null 2>&1 && exit 0

sudo pacman -S --needed --noconfirm base-devel git scenefx
recipe="$tmp/swayfx"
git clone --quiet --depth 1 https://aur.archlinux.org/swayfx.git "$recipe"
sed -i 's/"scenefx0\.5"/"scenefx"/' "$recipe/PKGBUILD"
# Built first; only then is sway swapped for it (pacman's --noconfirm would decline the swap, so sway
# goes out by hand), so a failed build leaves sway as it was. Should the install still fail, sway
# comes back: a session without a compositor is the one thing this mustn't leave behind.
(cd "$recipe" && makepkg -s --noconfirm)
had_sway=0
if pacman -Qq sway >/dev/null 2>&1; then
	had_sway=1
	sudo pacman -Rdd --noconfirm sway
fi
if ! sudo pacman -U --noconfirm "$recipe"/swayfx-*.pkg.tar.*; then
	((had_sway)) && sudo pacman -S --noconfirm sway
	die swayfx_install msg='the built package would not install; sway is back'
fi
log_info built name=swayfx
