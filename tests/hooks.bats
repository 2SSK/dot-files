#!/usr/bin/env bats
# .githooks/post-commit: a commit on main drops links to deleted files and relinks with stow.
# A throwaway repo, a fake stow, a throwaway $HOME.

setup() {
	export HOME="$BATS_TEST_TMPDIR/home" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$HOME/.config" "$HOME/.local" "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "stow $* in $(pwd)" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/stow"
	chmod +x "$BATS_TEST_TMPDIR/bin/stow"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
	export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
	live="$BATS_TEST_TMPDIR/live"
	git init -q -b main "$live"
	mkdir -p "$live/.githooks" "$live/.config/app"
	cp "$BATS_TEST_DIRNAME/../.githooks/post-commit" "$live/.githooks/"
	echo one >"$live/.config/app/old.conf"
	git -C "$live" add -A && git -C "$live" commit -qm first
	git -C "$live" config core.hooksPath .githooks
	rm -f "$CALLS"
	# a stow link to a file the next commit deletes, and one that isn't ours
	ln -s "$live/.config/app/old.conf" "$HOME/.config/old.conf"
	ln -s /nonexistent "$HOME/.config/other"
}

@test "a commit on main drops dead links and relinks" {
	echo two >"$live/new.conf"
	git -C "$live" rm -q .config/app/old.conf
	git -C "$live" add -A && git -C "$live" commit -qm second
	grep -qx "stow . in $live" "$CALLS"
	[ ! -L "$HOME/.config/old.conf" ] # the link to the deleted file is gone
	[ -L "$HOME/.config/other" ]      # a dead link elsewhere is left alone
}

@test "a commit on another branch does nothing" {
	git -C "$live" checkout -q -b other
	git -C "$live" rm -q .config/app/old.conf && git -C "$live" commit -qm other
	[ ! -e "$CALLS" ]
	[ -L "$HOME/.config/old.conf" ]
}
