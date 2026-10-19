#!/usr/bin/env bats
# tmux.conf on an isolated server (own socket, throwaway $HOME, no plugins installed).

setup() {
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME"
	CONF="$BATS_TEST_DIRNAME/../.config/tmux/tmux.conf"
	SOCK="bats-$$"
	tmux -L "$SOCK" -f "$CONF" new-session -d -s t
}

teardown() { tmux -L "$SOCK" kill-server 2>/dev/null || true; }

t() { tmux -L "$SOCK" "$@"; }

@test "config loads without errors" {
	run t show-messages
	[[ $output != *"error"* && $output != *"unknown"* ]]
}

@test "prefix is backtick and copy mode uses vi keys" {
	[ "$(t show -gv prefix)" = '`' ]
	[ "$(t show -gwv mode-keys)" = vi ]
}

@test "status bar uses ANSI colour names only, so it follows the theme" {
	run grep -nE '#[0-9a-fA-F]{6}' "$CONF"
	[ "$status" -eq 1 ]
	[ "$(t show -gv status-position)" = top ]
}

@test "splits keep the working directory" {
	run t list-keys -T prefix
	[[ $output == *' w '*'split-window -h -c "#{pane_current_path}"'* ]]
	[[ $output == *' s '*'split-window -v -c "#{pane_current_path}"'* ]]
}

@test "i3 and sway start tmux detached at login, so the saved sessions are there to attach to" {
	local line='exec --no-startup-id tmux-save start'
	grep -qxF "$line" "$BATS_TEST_DIRNAME/../.config/i3/conf.d/autostart.conf"
	grep -qxF "$line" "$BATS_TEST_DIRNAME/../.config/sway/desktop/startup.conf"
}

# tmux-save on its own tmux (TMUX_TMPDIR: never the live server), a fake resurrect save.sh
save_setup() {
	export TMUX_TMPDIR="$BATS_TEST_TMPDIR/sock" && mkdir -p "$TMUX_TMPDIR" && unset TMUX
	SAVE="$BATS_TEST_DIRNAME/../.local/bin/tmux-save"
	RES="$HOME/.tmux/resurrect" && mkdir -p "$RES"
	local s="$HOME/.config/tmux/plugins/tmux-resurrect/scripts"
	mkdir -p "$s" && printf '#!/bin/sh\necho "$1" >>"%s/saved"\n' "$BATS_TEST_TMPDIR" >"$s/save.sh" && chmod +x "$s/save.sh"
	printf '#!/bin/sh\necho restored >>"%s/restored"\n' "$BATS_TEST_TMPDIR" >"$s/restore.sh" && chmod +x "$s/restore.sh"
}

@test "tmux-save repair: a last pointing at a save that never got written goes to the newest good one" {
	save_setup
	printf 'pane\tx\n' >"$RES/tmux_resurrect_20261019T115429.txt"
	printf 'pane\tx\n' >"$RES/tmux_resurrect_20261019T113928.txt" && touch -d '1 hour ago' "$RES/tmux_resurrect_20261019T113928.txt"
	: >"$RES/tmux_resurrect_20261019T120000.txt" # empty: not a good save
	ln -s tmux_resurrect_20261019T134711.txt "$RES/last"
	run "$SAVE" repair
	[ "$status" -eq 0 ]
	[ "$(readlink "$RES/last")" = tmux_resurrect_20261019T115429.txt ]
}

@test "tmux-save repair: a good last is left alone" {
	save_setup
	printf 'pane\tx\n' >"$RES/a.txt" && printf 'pane\tx\n' >"$RES/tmux_resurrect_new.txt"
	ln -s a.txt "$RES/last"
	"$SAVE" repair
	[ "$(readlink "$RES/last")" = a.txt ]
}

@test "tmux-save: saves a server that's been up a while, never a missing or just-started one" {
	save_setup
	run "$SAVE"
	[ "$status" -eq 0 ] && [ ! -e "$BATS_TEST_TMPDIR/saved" ] # no server
	tmux new-session -d -s s
	run "$SAVE"
	[ ! -e "$BATS_TEST_TMPDIR/saved" ] # just started: it may not have restored yet
	TMUX_SAVE_MIN_AGE=0 run "$SAVE"
	tmux kill-server
	[ "$(cat "$BATS_TEST_TMPDIR/saved")" = quiet ]
}

@test "tmux-save start: a server, its sessions restored once (repaired first); a running one is left alone" {
	save_setup
	printf 'pane\tx\n' >"$RES/tmux_resurrect_20261019T115429.txt"
	ln -s tmux_resurrect_20261019T134711.txt "$RES/last" # cut short
	run "$SAVE" start
	[ "$status" -eq 0 ]
	[ "$(readlink "$RES/last")" = tmux_resurrect_20261019T115429.txt ]
	[ "$(cat "$BATS_TEST_TMPDIR/restored")" = restored ]
	run "$SAVE" start
	tmux kill-server
	[ "$(wc -l <"$BATS_TEST_TMPDIR/restored")" -eq 1 ]
}
