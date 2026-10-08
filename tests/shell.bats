#!/usr/bin/env bats
# zsh and bash configs, stowed into a throwaway $HOME (no plugins: those need the network).

setup_file() {
	export HOME="$BATS_FILE_TMPDIR/home"
	mkdir -p "$HOME"
	mkdir -p "$BATS_FILE_TMPDIR/bin" # fake pkill/xrdb/tmux: never touch the developer's terminals
	for tool in pkill xrdb tmux; do printf '#!/bin/sh\n' >"$BATS_FILE_TMPDIR/bin/$tool" && chmod +x "$BATS_FILE_TMPDIR/bin/$tool"; done
	export PATH="$BATS_FILE_TMPDIR/bin:$PATH"
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
	run zsh -i -c 'alias gs; whence -w y fkill frg fgl fdex cached_init'
	[ "$status" -eq 0 ]
	[[ $output == *"git status --short"* ]]
}

@test "bash starts without errors, with shared aliases and history" {
	run bash -i -c 'alias gs && echo "$HISTFILE"' 2>&1
	[ "$status" -eq 0 ]
	[[ $output == *"git status --short"* ]]
	[[ $output == *"$HOME/.local/state/bash/history" ]]
}

@test "env.sh dedupes PATH when sourced twice" {
	mkdir -p "$HOME/.local/bin"
	run sh -c '. "$HOME/.config/shell/env.sh"; . "$HOME/.config/shell/env.sh"; echo "$PATH"'
	[ "$(tr ':' '\n' <<<"$output" | grep -cx "$HOME/.local/bin")" -eq 1 ]
}

@test "top opens btop" {
	run zsh -i -c 'alias top'
	[ "$output" = "top=btop" ]
}

@test "ls uses eza when it is installed" {
	printf '#!/bin/sh\n' >"$BATS_FILE_TMPDIR/bin/eza" && chmod +x "$BATS_FILE_TMPDIR/bin/eza"
	PATH="$BATS_FILE_TMPDIR/bin:/usr/bin:/bin" run zsh -i -c 'alias ls ll lt'
	rm "$BATS_FILE_TMPDIR/bin/eza"
	[[ ${lines[0]} == "ls='eza --group-directories-first --icons=auto'" ]]
	[[ ${lines[1]} == "ll='ls -l --git'" ]]
	[[ ${lines[2]} == "lt='ls --tree --level=2'" ]]
}

@test "ls falls back to coloured GNU ls without eza" {
	mkdir -p "$BATS_FILE_TMPDIR/noeza"
	for tool in zsh ls dircolors; do ln -sf "$(command -v "$tool")" "$BATS_FILE_TMPDIR/noeza/$tool"; done
	PATH="$BATS_FILE_TMPDIR/noeza" run zsh -i -c 'alias ls'
	[ "$output" = "ls='ls --color=auto --group-directories-first -h'" ]
}

@test "ssh connects as xterm-256color from terminals servers rarely know" {
	printf '#!/bin/sh\necho "$TERM"\n' >"$BATS_FILE_TMPDIR/bin/ssh" && chmod +x "$BATS_FILE_TMPDIR/bin/ssh"
	run env TERM=xterm-kitty zsh -i -c 'ssh host'
	[ "${lines[-1]}" = xterm-256color ]
	run env TERM=foot bash -ic 'ssh host'
	[ "${lines[-1]}" = xterm-256color ]
	run env TERM=tmux-256color zsh -i -c 'ssh host' # widely known: passed through
	[ "${lines[-1]}" = tmux-256color ]
	rm "$BATS_FILE_TMPDIR/bin/ssh"
}

@test "zsh and bash point starship at ~/.config/starship/starship.toml, which loads cleanly" {
	run zsh -i -c 'print -r -- $STARSHIP_CONFIG' 2>&1
	[ "$output" = "$HOME/.config/starship/starship.toml" ]
	run bash -i -c 'echo "$STARSHIP_CONFIG"' # bash adds job-control notices without a terminal
	[ "${lines[-1]}" = "$HOME/.config/starship/starship.toml" ]
	[ -f "$HOME/.config/starship/starship.toml" ]
	command -v starship >/dev/null || skip 'starship not installed'
	run env STARSHIP_CONFIG="$HOME/.config/starship/starship.toml" starship prompt 2>&1
	[ "$status" -eq 0 ]
	[[ $output != *"[WARN]"* && $output != *"ERROR"* ]]
}
