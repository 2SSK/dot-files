#!/usr/bin/env bats
# .githooks/post-commit: a commit on rewrite fast-forwards main's worktree (the live checkout) and
# relinks it with stow. Throwaway repos, a fake stow, a throwaway $HOME.

setup() {
	export HOME="$BATS_TEST_TMPDIR/home" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$HOME/.config" "$HOME/.local" "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "stow $* in $(pwd)" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/stow"
	chmod +x "$BATS_TEST_TMPDIR/bin/stow"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
	export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
	live="$BATS_TEST_TMPDIR/live" work="$BATS_TEST_TMPDIR/work"
	git init -q -b main "$live"
	mkdir -p "$live/.githooks" "$live/.config/app"
	cp "$BATS_TEST_DIRNAME/../.githooks/post-commit" "$live/.githooks/"
	echo one >"$live/.config/app/old.conf"
	git -C "$live" add -A && git -C "$live" commit -qm first
	git -C "$live" config core.hooksPath .githooks
	git -C "$live" worktree add -q -b rewrite "$work"
	# a stow link to a file the next commit deletes
	ln -s "$live/.config/app/old.conf" "$HOME/.config/old.conf"
}

@test "a commit on rewrite fast-forwards main and relinks" {
	echo two >"$work/new.conf"
	git -C "$work" rm -q .config/app/old.conf
	git -C "$work" add -A && git -C "$work" commit -qm second
	[ "$(git -C "$live" rev-parse HEAD)" = "$(git -C "$work" rev-parse HEAD)" ]
	[ -f "$live/new.conf" ]
	grep -qx "stow . in $live" "$CALLS"
	[ ! -L "$HOME/.config/old.conf" ] # the link to the deleted file is gone
}

@test "a commit on another branch leaves main alone" {
	git -C "$work" checkout -q -b other
	echo x >"$work/x" && git -C "$work" add -A && git -C "$work" commit -qm other
	[ "$(git -C "$live" rev-parse HEAD)" != "$(git -C "$work" rev-parse HEAD)" ]
	[ ! -e "$CALLS" ]
}

@test "local changes in the way: main stays, the commit still succeeds" {
	echo mine >"$live/new.conf" # untracked, and rewrite adds the same file
	echo two >"$work/new.conf"
	git -C "$work" add -A
	run git -C "$work" commit -qm second
	[ "$status" -eq 0 ]
	[[ $output == *"main not updated"* ]]
	[ "$(cat "$live/new.conf")" = mine ]
}
