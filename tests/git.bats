#!/usr/bin/env bats
# git config through XDG (~/.config/git/config) in a throwaway $HOME.

setup() {
	export HOME="$BATS_TEST_TMPDIR/home" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/home/.config"
	unset GIT_CONFIG_GLOBAL
	export GIT_CONFIG_NOSYSTEM=1
	mkdir -p "$XDG_CONFIG_HOME/git"
	for f in config template ignore; do ln -s "$BATS_TEST_DIRNAME/../.config/git/$f" "$XDG_CONFIG_HOME/git/$f"; done
}

@test "delta is the pager" {
	[ "$(git config --get core.pager)" = delta ]
	[ "$(git config --get delta.syntax-theme)" = ansi ]
}

@test "colours come from the rendered theme include" {
	XDG_STATE_HOME="$HOME/.local/state" python3 "$BATS_TEST_DIRNAME/../.local/lib/desktop/theme_render.py" render gruvbox dark
	[ "$(git config --get color.branch.current)" = "#8ec07c bold" ]
	[ "$(git config --get delta.minus-emph-style)" = "#282828 #fb4934" ]
}

@test "identity comes from the untracked local.gitconfig" {
	printf '[user]\n\tname = Someone\n' >"$XDG_CONFIG_HOME/git/local.gitconfig"
	[ "$(git config user.name)" = Someone ]
}

@test "works before the theme or local.gitconfig exist" {
	run git config --list
	[ "$status" -eq 0 ]
}
