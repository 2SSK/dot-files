#!/usr/bin/env bats
# git config through XDG (~/.config/git/config) in a throwaway $HOME.

setup() {
	export HOME="$BATS_TEST_TMPDIR/home" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/home/.config"
	unset GIT_CONFIG_GLOBAL
	export GIT_CONFIG_NOSYSTEM=1
	mkdir -p "$XDG_CONFIG_HOME/git"
	for f in config template ignore; do ln -s "$BATS_TEST_DIRNAME/../.config/git/$f" "$XDG_CONFIG_HOME/git/$f"; done
}

@test "delta is the pager and colours are ANSI names only" {
	[ "$(git config --get core.pager)" = delta ]
	[ "$(git config --get delta.syntax-theme)" = ansi ]
	run grep -nE '#[0-9a-fA-F]{6}' "$XDG_CONFIG_HOME/git/config"
	[ "$status" -eq 1 ]
}

@test "identity comes from untracked files, switched by directory" {
	printf '[user]\n\tname = Default\n' >"$XDG_CONFIG_HOME/git/local.gitconfig"
	printf '[user]\n\temail = me@personal.test\n' >"$XDG_CONFIG_HOME/git/personal.gitconfig"
	printf '[user]\n\temail = me@work.test\n' >"$XDG_CONFIG_HOME/git/work.gitconfig"
	git init -q "$HOME/Code/a" && git init -q "$HOME/Work/b"
	[ "$(git -C "$HOME/Code/a" config user.name)" = Default ]
	[ "$(git -C "$HOME/Code/a" config user.email)" = me@personal.test ]
	[ "$(git -C "$HOME/Work/b" config user.email)" = me@work.test ]
}

@test "missing untracked files are fine" {
	run git config --list
	[ "$status" -eq 0 ]
}

@test "gh: expands to GitHub" {
	run git ls-remote --get-url gh:user/repo
	[ "$output" = "https://github.com/user/repo" ]
}
