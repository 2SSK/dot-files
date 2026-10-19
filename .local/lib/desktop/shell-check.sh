#!/usr/bin/env bash
# Does the shell's config load? It runs in a throwaway headless sway, apart from everything live (its
# own D-Bus and state; no swayidle or Bluetooth agent of its own), all in one systemd scope that is
# stopped at the end with whatever D-Bus started in it; any load or script error is printed.
# desktop-reload runs it before restarting the shell, and CI on each push.
#   shell-check.sh [config dir]      exit 0: it loads clean
set -uo pipefail

lib="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
repo="$(cd "$lib/../../.." && pwd)"
cfg="$(readlink -f "${1:-$repo/.config/quickshell/desktop}")"
[[ -f $cfg/shell.qml ]] || { echo "shell-check: no shell.qml in $cfg" >&2 && exit 2; }

w="$(mktemp -d)"
unit="shell-check-$$"
# a systemd scope where there's a user session; else (CI's container) a process group of its own
if systemctl --user show-environment >/dev/null 2>&1; then
	run=(systemd-run --user --scope --quiet --unit="$unit" -p MemoryMax=2G)
	trap 'systemctl --user stop "$unit.scope" 2>/dev/null; rm -rf "$w"' EXIT
else
	run=(setsid)
	trap 'kill -- -"$sway" 2>/dev/null; rm -rf "$w"' EXIT
fi
mkdir -p "$w/state/desktop" "$w/config/desktop" "$w/bin"
[[ -n ${XDG_RUNTIME_DIR:-} ]] || { export XDG_RUNTIME_DIR="$w/run" && mkdir -m 700 "$w/run"; }

# the theme it reads: the one rendered here, else the default rendered for it
if [[ -d ${XDG_STATE_HOME:-$HOME/.local/state}/desktop/theme ]]; then
	cp -rL "${XDG_STATE_HOME:-$HOME/.local/state}/desktop/theme" "$w/state/desktop/theme"
else
	XDG_STATE_HOME="$w/state" python3 "$lib/theme_render.py" render tokyonight dark
fi
cp "$repo/.config/desktop/shell.json" "$w/config/desktop/shell.json"
for tool in swayidle bluetoothctl; do printf '#!/bin/sh\nexec sleep infinity\n' >"$w/bin/$tool" && chmod +x "$w/bin/$tool"; done

# shellcheck disable=SC2016 # $PATH expands when run.sh runs
printf '#!/bin/sh\nexec dbus-run-session -- env PATH=%s:"$PATH" XDG_STATE_HOME=%s XDG_CONFIG_HOME=%s QT_QPA_PLATFORM=wayland qs -p %s >%s 2>&1\n' \
	"$w/bin" "$w/state" "$w/config" "$cfg" "$w/qs.log" >"$w/run.sh"
chmod +x "$w/run.sh"
printf 'output HEADLESS-1 resolution 1280x800\nexec %s\n' "$w/run.sh" >"$w/sway.conf"

env -u WAYLAND_DISPLAY -u SWAYSOCK -u DISPLAY WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 \
	"${run[@]}" sway -c "$w/sway.conf" >"$w/sway.log" 2>&1 &
sway=$!

result=""
for _ in $(seq 120); do
	result="$(sed 's/\x1b\[[0-9;]*m//g' "$w/qs.log" 2>/dev/null | grep -aoE 'Configuration Loaded|Failed to load configuration' | head -1)"
	[[ -n $result ]] && break
	kill -0 "$sway" 2>/dev/null || break
	sleep 0.25
done
[[ $result == "Configuration Loaded" ]] && sleep 3 # and the errors of its first moments

# QML's own errors (services like pipewire may complain in a headless session: not the config's fault)
errors="$(sed 's/\x1b\[[0-9;]*m//g' "$w/qs.log" 2>/dev/null |
	grep -aE 'caused by|TypeError|ReferenceError|is not defined|is not a function|is not a type|Unable to assign|Cannot assign|Cannot read|Invalid property assignment|read-only property')"
if [[ $result == "Configuration Loaded" && -z $errors ]]; then
	echo "shell-check: loads clean"
	exit 0
fi
echo "shell-check: ${result:-no answer (sway: $(tail -1 "$w/sway.log"))}" >&2
[[ -n $errors ]] && printf '%s\n' "$errors" | head -20 >&2
exit 1
