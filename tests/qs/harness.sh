#!/usr/bin/env bash
# A copy of the desktop shell in a hidden headless sway, with its own config and state (a frozen
# copy of the theme), for screenshots before and after a change and a log to check for errors.
# Never touches the live shell, its settings or its state. Local tool, like the tests.
#   harness.sh start | stop | reload | reload-ref <git ref> | ipc <target> <function> [arg]
set -euo pipefail
T="${XDG_CACHE_HOME:-$HOME/.cache}/qs-test"
running() { pgrep -f "qs -p $T/cfg$" || true; }
nested_sock() { ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | while read -r s; do SWAYSOCK=$s swaymsg -t get_outputs 2>/dev/null | grep -q HEADLESS-1 && echo "$s"; done | head -1; }
relaunch() {
	for p in $(running); do kill "$p"; done
	sleep 0.7
	SWAYSOCK="$(nested_sock)" swaymsg -q exec "$T/run.sh > $T/qs.log 2>&1"
	sleep 4
}
case $1 in
start)
	"$0" stop
	rm -rf "$T" && mkdir -p "$T/state/desktop" "$T/xdg/desktop"
	cp -r ~/dot-files/.config/quickshell/desktop "$T/cfg"
	cp -rL ~/.local/state/desktop/theme "$T/state/desktop/theme"
	ln -s "$(readlink -f ~/.local/state/desktop/wallpaper)" "$T/state/desktop/wallpaper"
	date +%s >"$T/state/desktop/wallpaper-changed"
	jq '.bar.right = ["clipboard","notes","todo","wifi","bluetooth","notifications","controls","recorder","battery","power"] | .bar.style = "island"' \
		~/.config/desktop/shell.json >"$T/xdg/desktop/shell.json"
	# its own D-Bus session: it mustn't take the notifications, the tray or the polkit agent from the
	# live shell (it did, once, when the live one restarted while this ran)
	# and no swayidle of its own: in this login session it would answer the live session's lock
	# and no pairing agent of its own: it would take over the live shell's
	mkdir -p "$T/bin" && printf '#!/bin/sh\nexec sleep infinity\n' >"$T/bin/swayidle" && chmod +x "$T/bin/swayidle"
	cp "$T/bin/swayidle" "$T/bin/bluetoothctl"
	printf '#!/bin/sh\nexec dbus-run-session -- env PATH=%s:"$PATH" XDG_STATE_HOME=%s XDG_CONFIG_HOME=%s QT_QPA_PLATFORM=wayland qs -p %s\n' "$T/bin" "$T/state" "$T/xdg" "$T/cfg" >"$T/run.sh"
	chmod +x "$T/run.sh"
	# no SwayFX effects: blur on a headless output stops drawing after a while (red, then nothing)
	{ echo "output HEADLESS-1 resolution 1600x1000"; echo "exec $T/run.sh > $T/qs.log 2>&1"; } >"$T/sway.conf"
	displays() { for d in "$XDG_RUNTIME_DIR"/wayland-*; do if [[ -S $d && ${d##*/} =~ ^wayland-[0-9]+$ ]]; then echo "${d##*/}"; fi; done; }
	before=$(displays)
	(env -u WAYLAND_DISPLAY -u SWAYSOCK -u DISPLAY WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 systemd-run --user --scope -q --unit=qs-harness -p MemoryMax=2G -p CPUQuota=200% sway -c "$T/sway.conf" >"$T/sway.log" 2>&1 &)
	sleep 5
	comm -13 <(echo "$before" | sort) <(displays | sort) | head -1 >"$T/display"
	;;
stop)
	for p in $(running); do kill "$p"; done
	for p in $(pgrep -f "sway -c $T/sway.conf" || true); do kill "$p"; done
	systemctl --user stop qs-harness.scope 2>/dev/null || true # and what D-Bus started for it
	;;
reload) rm -rf "$T/cfg" && cp -r ~/dot-files/.config/quickshell/desktop "$T/cfg" && relaunch ;;
reload-ref)
	rm -rf "$T/cfg" "$T/ref" && mkdir -p "$T/ref"
	git -C ~/dot-files archive "$2" .config/quickshell/desktop | tar -x -C "$T/ref"
	mv "$T/ref/.config/quickshell/desktop" "$T/cfg" && relaunch
	;;
ipc) shift && WAYLAND_DISPLAY="$(cat "$T/display")" timeout 10 qs -p "$T/cfg" ipc call "$@" ;;
esac
