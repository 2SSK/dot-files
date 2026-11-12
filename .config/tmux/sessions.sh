#!/usr/bin/env bash
# tmux sessions through fzf (prefix + Space opens it in a popup; ts in a shell): the most recent
# first, each previewed by its active pane. Enter goes there (switches inside tmux, attaches outside),
# a name that isn't one makes it, Ctrl-X kills the one under the cursor.
#   sessions.sh            pick
#   sessions.sh --list     the names, most recent first
if [[ ${1:-} == --list ]]; then
	tmux list-sessions -F '#{session_activity} #{session_name}' 2>/dev/null | sort -rn | cut -d' ' -f2-
	exit
fi
out="$("$0" --list | fzf --print-query --prompt='tmux> ' --header='enter: go · new name: make it · ctrl-x: kill' \
	--preview 'tmux capture-pane -ep -t {}' --preview-window=right:60% \
	--bind "ctrl-x:execute-silent(tmux kill-session -t {})+reload($0 --list)")"
(($? == 130)) && exit 0 # Escape
name="$(tail -1 <<<"$out")" # the pick, else what was typed
[[ -n $name ]] || exit 0
tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name"
if [[ -n ${TMUX:-} ]]; then tmux switch-client -t "=$name"; else tmux attach -t "=$name"; fi
