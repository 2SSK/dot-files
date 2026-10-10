#!/usr/bin/env bash
# Quickshell (the desktop shell) where the distro has no package. Fedora: the errornointernet COPR
# (the same release as Arch). Debian and Ubuntu: built from the pinned source against the system Qt
# (it needs Qt 6.6+; install.sh --check refuses older), into /usr/local.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.3.2
[[ $(quickshell --version 2>/dev/null) == *"$version"* ]] && exit 0

case "$(distro)" in
fedora)
	sudo dnf install -y dnf5-plugins >/dev/null 2>&1 || sudo dnf install -y dnf-plugins-core
	sudo dnf copr enable -y errornointernet/quickshell
	sudo dnf install -y quickshell
	;;
debian)
	sudo apt-get install -y --no-install-recommends cmake ninja-build pkgconf g++ spirv-tools \
		qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-declarative-private-dev \
		qt6-shadertools-dev qt6-wayland-dev qt6-wayland-private-dev qt6-svg-dev libcli11-dev \
		wayland-protocols libwayland-dev libdrm-dev libgbm-dev libpipewire-0.3-dev libpam0g-dev \
		libpolkit-agent-1-dev libglib2.0-dev libjemalloc-dev libxcb1-dev \
		qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtquick-effects \
		qml6-module-qtquick-layouts qml6-module-qtquick-shapes qml6-module-qtqml-workerscript \
		qml6-module-qtwayland-compositor qt6-wayland
	f="$(fetch "https://git.outfoxxed.me/quickshell/quickshell/archive/v$version.tar.gz" f14115a73c9fff6aa6399f924b632e88c3ce2cead2657f814a7825341f35baad)"
	tar -xzf "$f" -C "$tmp"
	cmake -S "$tmp/quickshell" -B "$tmp/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_INSTALL_PREFIX=/usr/local -DCRASH_HANDLER=OFF -DDISTRIBUTOR="dot-files (source)"
	cmake --build "$tmp/build"
	sudo cmake --install "$tmp/build"
	;;
*) log_error unsupported name=quickshell && exit 3 ;;
esac
log_info installed name=quickshell version="$version"
