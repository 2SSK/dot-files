#!/bin/sh
# After a client attaches (tmux.conf's client-attached hook): the display variables tmux took from the
# client into that session become the global ones, and every session's own copy goes, so all fall
# back to them. Switching sessions doesn't update a session's copy: a session last attached under i3
# kept i3's DISPLAY and XAUTHORITY under sway, and the clipboard failed (X: "Authorization required").
# The shells take the global ones before each command (zsh/tools.zsh).
#   env-sync.sh SESSION
vars="DISPLAY WAYLAND_DISPLAY XAUTHORITY SWAYSOCK I3SOCK XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE"
for var in $vars; do
	line="$(tmux show-environment -t "$1" "$var" 2>/dev/null)" || continue
	case $line in
	-*) tmux set-environment -gr "$var" ;; # marked removed, so the shells unset it too
	*) tmux set-environment -g "$var" "${line#*=}" ;;
	esac
	for session in $(tmux list-sessions -F '#{session_id}'); do
		tmux set-environment -t "$session" -u "$var" 2>/dev/null
	done
done
exit 0
