#!/usr/bin/env bash
# i3lock-color (the themed i3 lock screen) where the distro has no package: built from the pinned
# source into /usr/local, its PAM file in /etc/pam.d.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=2.13.c.5
[[ $(i3lock --version 2>&1) == *"$version"* ]] && exit 0
case "$(distro)" in
fedora)
	sudo dnf install -y autoconf automake gcc make pkgconf cairo-devel fontconfig-devel libev-devel \
		libjpeg-turbo-devel libXinerama-devel libxkbcommon-devel libxkbcommon-x11-devel libXrandr-devel \
		pam-devel xcb-util-image-devel xcb-util-xrm-devel giflib-devel
	;;
esac
f="$(fetch "https://github.com/Raymo111/i3lock-color/archive/refs/tags/$version.tar.gz" 46f15cbbf339873266e014f70b5e1ec02177f0295302b615a7bd85bef40d8ad2)"
tar -xzf "$f" -C "$tmp"
# as its own install script does: configured from a separate build folder (in-tree, make stops at
# "No rule to make target all-configured")
cd "$tmp/i3lock-color-$version"
autoreconf -fi >/dev/null
mkdir build && cd build
../configure --prefix=/usr/local --sysconfdir=/etc --disable-sanitizers >/dev/null
make -j"$(nproc)" >/dev/null
sudo make install >/dev/null
log_info installed name=i3lock-color version="$version"
