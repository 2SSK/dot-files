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

@test "pins to a commit as well as a tag, and stays offline after" {
	git -C "$REMOTE" config uploadpack.allowAnySHA1InWant true
	sha="$(git -C "$REMOTE" rev-parse v1)"
	commit_tag v2
	list "p/demo file://$REMOTE $sha"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 0 ]
	[ "$(cat "$HOME/p/demo/version")" = v1 ]
	rm -rf "$REMOTE"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 0 ]
}

# a fake codium: what it has installed in $HOME/codium
codium_fake() {
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '%s\n' '#!/bin/sh' 'case $1 in' \
		'--list-extensions) cat "$HOME/codium" 2>/dev/null ;;' \
		'--install-extension) echo "install $2" >>"$HOME/calls"; echo "$2" >>"$HOME/codium" ;;' \
		'esac' >"$BATS_TEST_TMPDIR/bin/codium"
	chmod +x "$BATS_TEST_TMPDIR/bin/codium"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH" VSCODIUM_EXTENSIONS="$BATS_TEST_TMPDIR/vscodium.txt"
	unset XDG_CONFIG_HOME XDG_STATE_HOME
	printf '%s\n' "# comment" "vscodevim.vim 1.32.4" "golang.go 0.56.1" >"$VSCODIUM_EXTENSIONS"
	list "# none"
}

@test "VSCodium: the pinned extensions, then its settings written from the base" {
	codium_fake
	mkdir -p "$HOME/.config/VSCodium" && printf '{\n\t"editor.fontSize": 14\n}\n' >"$HOME/.config/VSCodium/settings.jsonc"
	run "$PLUGINS" "$LIST"
	[ "$status" -eq 0 ]
	grep -qx "install vscodevim.vim@1.32.4" "$HOME/calls"
	grep -qx "install golang.go@0.56.1" "$HOME/calls"
	grep -q '"editor.fontSize": 14' "$HOME/.config/VSCodium/User/settings.json"
}

@test "VSCodium: a second run installs nothing; a version bump installs just that one" {
	codium_fake
	"$PLUGINS" "$LIST"
	rm "$HOME/calls"
	run "$PLUGINS" "$LIST"
	[ ! -e "$HOME/calls" ]
	sed -i 's/golang.go 0.56.1/golang.go 0.57.0/' "$VSCODIUM_EXTENSIONS"
	run "$PLUGINS" "$LIST"
	[ "$(cat "$HOME/calls")" = "install golang.go@0.57.0" ]
}
