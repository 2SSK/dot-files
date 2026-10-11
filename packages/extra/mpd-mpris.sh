#!/usr/bin/env bash
# mpd-mpris (media keys and the bar for mpd) where the distro has none: pinned release, and its
# user service (the Arch package ships one).
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.4.4
unit="$HOME/.config/systemd/user/mpd-mpris.service"
# it can't print its version, so the installed one is noted beside it: a new pin reinstalls
stamp="$bin/.mpd-mpris.version"
if [[ ! -x $bin/mpd-mpris || $(cat "$stamp" 2>/dev/null) != "$version" ]]; then
	f="$(fetch "https://github.com/natsukagami/mpd-mpris/releases/download/v$version/mpd-mpris_${version}_linux_amd64.tar.gz" 33f0a3322267f23ea5ac4ee9b5248894e0ad52410e0c2b3c9302effbcb3c5d57)"
	tar -xzf "$f" -C "$tmp" mpd-mpris
	install -D -m 755 "$tmp/mpd-mpris" "$bin/mpd-mpris"
	echo "$version" >"$stamp"
	log_info installed name=mpd-mpris version="$version"
fi
[[ -f $unit ]] || install -D -m 644 /dev/stdin "$unit" <<UNIT
[Unit]
Description=MPRIS for mpd (media keys, the desktop bar)
After=mpd.service

[Service]
ExecStart=$bin/mpd-mpris -no-instance

[Install]
WantedBy=default.target
UNIT
