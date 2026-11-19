#!/usr/bin/env bash
# Opens every panel and page of the harness's shell, screenshots each into <dir> (under the
# harness's folder), and prints the errors the shell logged meanwhile.
set -uo pipefail
h="$(dirname "$(readlink -f "$0")")/harness.sh"
T="${XDG_CACHE_HOME:-$HOME/.cache}/qs-test"
out="$T/$1" && rm -rf "$out" && mkdir -p "$out"
shot() { sleep "${2:-1.2}"; WAYLAND_DISPLAY=$(cat "$T/display") grim "$out/$1.png"; }
for p in home calendar system notifications wifi bluetooth todo notes; do "$h" ipc control open "$p"; shot "control-$p"; done
"$h" ipc control close; sleep 0.6
for m in apps files emoji themes; do "$h" ipc launcher toggle "$m"; shot "launcher-$m" 1.5; done
"$h" ipc launcher close; sleep 0.6
for t in clipboard wallpaper capture; do "$h" ipc "$t" toggle; shot "$t" 1.5; "$h" ipc "$t" toggle; sleep 0.6; done
"$h" ipc power open; shot power; "$h" ipc power next; "$h" ipc power close; sleep 0.6
for p in bar appearance notifications levels power timeshift keys; do "$h" ipc settings page "$p"; shot "settings-$p" 1.5; done
"$h" ipc settings toggle; sleep 0.5
grep -iE 'ReferenceError|TypeError|is not defined|is not a type|unavailable|ERROR' "$T/qs.log" | grep -v polkit | sort | uniq -c
