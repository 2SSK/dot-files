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
