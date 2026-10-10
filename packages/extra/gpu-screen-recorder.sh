#!/usr/bin/env bash
# gpu-screen-recorder (the shell's screen recording) where the distro has no package: its Flatpak
# from Flathub (for you), and a gpu-screen-recorder command in ~/.local/bin that runs it, so the
# capture panel and desktop-capture find it as on Arch.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
app=com.dec05eba.gpu_screen_recorder
command -v flatpak >/dev/null || case "$(distro)" in
	debian) sudo apt-get install -y flatpak ;;
	fedora) sudo dnf install -y flatpak ;;
esac
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak info --user "$app" >/dev/null 2>&1 || flatpak install --user -y --noninteractive flathub "$app"
install -D -m 755 /dev/stdin "$bin/gpu-screen-recorder" <<WRAP
#!/bin/sh
# gpu-screen-recorder from its Flatpak (packages/extra/gpu-screen-recorder.sh)
exec flatpak run --command=gpu-screen-recorder $app "\$@"
WRAP
log_info installed name=gpu-screen-recorder via=flatpak
