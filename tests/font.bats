#!/usr/bin/env bats
# desktop font: one font collection for the whole desktop. A fake fc-list says which fonts are
# installed; a fake theme records the re-render instead of touching the real desktop.

setup() {
	FONT="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/font"
	export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" CALLS="$BATS_TEST_TMPDIR/calls"
	export INSTALLED="Inter
Inter Display
JetBrainsMono Nerd Font
Geist"
	mkdir -p "$XDG_CONFIG_HOME/desktop" "$BATS_TEST_TMPDIR/bin"
	printf '{\n    "bar": {\n        "style": "island"\n    },\n    "fonts": {\n        "scale": 1.15\n    }\n}\n' >"$XDG_CONFIG_HOME/desktop/shell.json"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\nprintf "%%s\\n" "$INSTALLED"\n' >"$BATS_TEST_TMPDIR/bin/fc-list"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "theme $*" >>"$CALLS"\n[ "$1" = current ] && echo "gruvbox light"\nexit 0\n' >"$BATS_TEST_TMPDIR/bin/theme"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "pkill $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/pkill"
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

collection() { python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["fonts"].get("collection", ""))' "$XDG_CONFIG_HOME/desktop/shell.json"; }

@test "list: every collection, the current one marked, and what's missing" {
	run "$FONT" list
	[ "$status" -eq 0 ]
	[[ $output == *"* inter"*"Inter + JetBrains Mono"* ]]
	[[ $output == *"  geist"*"missing: GeistMono Nerd Font"* ]]
	[[ $output == *"  sf"*"missing: SF Pro Text, SF Compact Display, SF Mono"* ]]
}

@test "current: the saved collection, inter when none is" {
	run "$FONT" current
	[ "$output" = inter ]
}

@test "set: saves it in shell.json, keeps the rest, renders the current theme again, reloads kitty" {
	export INSTALLED="$INSTALLED
GeistMono Nerd Font"
	run "$FONT" set geist
	[ "$status" -eq 0 ]
	[ "$(collection)" = geist ]
	python3 -c '
import json, sys
c = json.load(open(sys.argv[1]))
assert c["fonts"]["scale"] == 1.15 and c["bar"] == {"style": "island"}, c' "$XDG_CONFIG_HOME/desktop/shell.json"
	grep -q '^    "fonts": {' "$XDG_CONFIG_HOME/desktop/shell.json" # four spaces, as the shell writes it
	grep -qx "theme set gruvbox --mode light" "$CALLS"
	grep -qx "pkill -USR1 -x kitty" "$CALLS" # kitty reads its config again: the new font
}

@test "set: a collection whose fonts aren't installed is refused, nothing changed" {
	run "$FONT" set sf
	[ "$status" -eq 1 ]
	[[ $output == *"SF Pro Text"* && $output == *"apple-fonts"* ]]
	[ -z "$(collection)" ]
	[ ! -e "$CALLS" ]
}

@test "set: an unknown collection or no name is a usage error" {
	run "$FONT" set comic
	[ "$status" -eq 2 ]
	run "$FONT" set
	[ "$status" -eq 2 ]
}
