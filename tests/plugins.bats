#!/usr/bin/env bats
# packages/plugins.sh against local git repos and a throwaway $HOME.

setup() {
	PLUGINS="$BATS_TEST_DIRNAME/../packages/plugins.sh"
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME"
	export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
	REMOTE="$BATS_TEST_TMPDIR/remote"
	git init -q -b main "$REMOTE"
	commit_tag v1
	LIST="$BATS_TEST_TMPDIR/plugins.txt"
}

commit_tag() {
	echo "$1" >"$REMOTE/version"
	git -C "$REMOTE" add version
	git -C "$REMOTE" -c user.name=t -c user.email=t@t commit -q -m "$1"
	git -C "$REMOTE" tag "$1"
}

list() { printf '%s\n' "$@" >"$LIST"; }

@test "clones at the pinned tag" {
	list "# comment" "p/demo file://$REMOTE v1"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 0 ]
	[ "$(cat "$HOME/p/demo/version")" = v1 ]
}

@test "second run is offline and a no-op" {
	list "p/demo file://$REMOTE v1"
	"$PLUGINS" "$LIST"
	rm -rf "$REMOTE"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 0 ]
}

@test "moves to a new tag" {
	list "p/demo file://$REMOTE v1"
	"$PLUGINS" "$LIST"
	commit_tag v2
	list "p/demo file://$REMOTE v2"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 0 ]
	[ "$(cat "$HOME/p/demo/version")" = v2 ]
}

@test "build runs once per tag and again after a failed build" {
	list "p/demo file://$REMOTE v1 echo built >>$HOME/builds"
	"$PLUGINS" "$LIST"
	"$PLUGINS" "$LIST"
	[ "$(wc -l <"$HOME/builds")" -eq 1 ]

	list "p/fail file://$REMOTE v1 false"
	run "$PLUGINS" "$LIST"
	[ "$status" -ne 0 ]
	list "p/fail file://$REMOTE v1 echo fixed >>$HOME/builds"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 0 ]
	[ "$(tail -1 "$HOME/builds")" = fixed ]
}

@test "refuses to touch an existing non-git directory" {
	mkdir -p "$HOME/p/demo"
	list "p/demo file://$REMOTE v1"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 1 ]
	[[ $output == *"event=not_a_clone"* ]]
}
