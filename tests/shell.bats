#!/usr/bin/env bats
# zsh and bash configs, stowed into a throwaway $HOME (no plugins: those need the network).

setup_file() {
	export HOME="$BATS_FILE_TMPDIR/home"
	mkdir -p "$HOME"
	"$BATS_TEST_DIRNAME/../setup.sh" -y --no-packages >/dev/null
}

setup() {
	export HOME="$BATS_FILE_TMPDIR/home"
	unset ZDOTDIR XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME
}

@test "zsh starts without errors and keeps its files under XDG dirs" {
	run zsh -i -c 'print -r -- $ZDOTDIR $HISTFILE' 2>&1
	[ "$status" -eq 0 ]
	[ "$output" = "$HOME/.config/zsh $HOME/.local/state/zsh/history" ]
}

@test "zsh uses vim mode with jk" {
	run zsh -i -c 'bindkey -lL main; bindkey -M viins jk'
	[[ $output == *"bindkey -A viins main"* ]]
	[[ $output == *"vi-cmd-mode"* ]]
}

@test "zsh loads shared aliases and functions" {
	run zsh -i -c 'alias gs; whence -w fkill frg fgl fdex cached_init'
	[ "$status" -eq 0 ]
	[[ $output == *"git status --short"* ]]
}

@test "bash starts without errors, in vi mode, with shared aliases" {
	run bash -i -c 'shopt -qo vi && alias gs && echo "$HISTFILE"' 2>&1
	[ "$status" -eq 0 ]
	[[ $output == *"git status --short"* ]]
	[[ $output == *"$HOME/.local/state/bash/history" ]]
}

@test "env.sh dedupes PATH when sourced twice" {
	mkdir -p "$HOME/.local/bin"
	run sh -c '. "$HOME/.config/shell/env.sh"; . "$HOME/.config/shell/env.sh"; echo "$PATH"'
	[ "$(tr ':' '\n' <<<"$output" | grep -cx "$HOME/.local/bin")" -eq 1 ]
}
