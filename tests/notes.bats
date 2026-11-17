#!/usr/bin/env bats
# desktop notes: Markdown notes in ~/.local/share/desktop/notes, from a terminal and in rofi (a fake
# that answers what each test lines up: see rofi.bash). kitty is a fake recording what it opens.

setup() {
	load rofi
	NOTES="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/notes"
	export CALLS="$BATS_TEST_TMPDIR/calls" HOME="$BATS_TEST_TMPDIR/home"
	export XDG_DATA_HOME="$HOME/.local/share"
	DIR="$XDG_DATA_HOME/desktop/notes"
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin" "$DIR"
	fake_rofi "$bin"
	for tool in kitty notify-send; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$bin/$tool"
	done
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "desktop $*" >>"$CALLS"\ncat >>"$CALLS"\necho >>"$CALLS"\n' >"$bin/desktop"
	printf '#!/bin/sh\nprintf "copied\\nlines"\n' >"$bin/xclip"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH"
	unset WAYLAND_DISPLAY
}

opened() { # waits for kitty (started in the background) to be asked to open something
	for _ in $(seq 50); do
		grep -q "^kitty" "$CALLS" 2>/dev/null && return 0
		sleep 0.05
	done
	return 1
}

@test "quick: a timestamped line in the inbox" {
	"$NOTES" quick "a thought"
	grep -qE '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\] a thought$' "$DIR/inbox.md"
}

@test "clip: the clipboard in the inbox as an indented block" {
	"$NOTES" clip
	grep -qE '^\[.*\] \[clipboard\]$' "$DIR/inbox.md"
	[ "$(tail -n 2 "$DIR/inbox.md")" = "$(printf '    copied\n    lines')" ]
	"$NOTES" clip "given text"
	grep -qx "    given text" "$DIR/inbox.md"
}

@test "migrate: each note of the shell's notes.json becomes a file" {
	printf '%s' '{"notes":[{"title":"Commands","type":"code","body":"ls -la","items":[],"updated":1700000000000},
		{"title":"a/b","type":"checklist","body":"","items":[{"done":true,"text":"x"},{"done":false,"text":"y"}]},
		{"title":"","type":"text","body":"First line\nmore","items":[]}]}' >"$DIR/notes.json"
	"$NOTES" migrate
	[ -f "$DIR/notes.json.bak" ] && [ ! -e "$DIR/notes.json" ]
	[ "$(cat "$DIR/Commands.md")" = "$(printf '# Commands\n\n```\nls -la\n```')" ]
	[ "$(stat -c %Y "$DIR/Commands.md")" -eq 1700000000 ]
	[ "$(cat "$DIR/a-b.md")" = "$(printf '# a/b\n\n- [x] x\n- [ ] y')" ]
	grep -qx "First line" "$DIR/First line.md"
}

@test "menu: the inbox, a search, the notes and the projects" {
	"$NOTES" quick one && "$NOTES" quick two
	printf '# A\n' >"$DIR/A.md"
	mkdir -p "$DIR/work" && printf '# B\n' >"$DIR/work/B.md"
	run "$NOTES"
	[ "$status" -eq 0 ]
	[[ $(rows 1 | sed -n 1p) == *"Inbox   ·  2" ]]
	[[ $(rows 1 | sed -n 2p) == *"Search every note" ]]
	[[ $(rows 1 | sed -n 3p) == *"A   ·  "* ]]
	[[ $(rows 1 | sed -n 4p) == *"work   ·  1 notes" ]]
}

@test "menu: a new name and Enter starts a note and opens it in nvim" {
	answer 0 "-1 Meeting notes"
	"$NOTES"
	[ "$(cat "$DIR/Meeting notes.md")" = "# Meeting notes" ]
	opened
	grep -qx "kitty --class desktop-notes --title Meeting notes --directory $DIR nvim +3 $DIR/Meeting notes.md" "$CALLS"
}

@test "menu: Alt+q keeps the typed text in the inbox; Alt+v the clipboard" {
	answer 10 "-1 remember this"
	"$NOTES"
	grep -q "\] remember this$" "$DIR/inbox.md"
	answer 13 "0 "
	"$NOTES"
	grep -q "\[clipboard\]$" "$DIR/inbox.md"
}

@test "menu: a note moves into a project (new or not), and deletes after asking" {
	printf '# A\n' >"$DIR/A.md" && printf '# C\n' >"$DIR/C.md" && touch -d '-1 hour' "$DIR/C.md"
	answer 12 "2 "     # Alt+m on A
	answer 0 "-1 work" # a new project, typed
	answer 11 "2 "     # Alt+d on C (now the only note left)
	answer 0 "1 "      # Delete
	"$NOTES"
	[ -f "$DIR/work/A.md" ] && [ ! -e "$DIR/A.md" ] && [ ! -e "$DIR/C.md" ]
}

@test "inbox: Enter copies an entry; Alt+m files it into a project's note; Alt+d drops it" {
	"$NOTES" quick first && "$NOTES" quick second && "$NOTES" quick third
	answer 0 "0 " # the inbox
	answer 0 "0 " # newest first: third, copied
	"$NOTES"
	grep -q "^desktop clipboard copy text" "$CALLS" && grep -qx "third" "$CALLS"
	: >"$BATS_TEST_TMPDIR/rofi-count" && : >"$ROFI_ANSWERS"
	answer 0 "0 "       # the inbox
	answer 10 "1 "      # Alt+m on second
	answer 0 "-1 ideas" # a new project
	answer 0 "-1 list"  # its note
	answer 11 "0 "      # Alt+d on third
	"$NOTES"
	[ "$(cat "$DIR/ideas/list.md")" = "$(printf '# list\n\nsecond')" ]
	[ "$(grep -c . "$DIR/inbox.md")" -eq 1 ] && grep -q "\] first$" "$DIR/inbox.md"
}

@test "search: every line of every note; Enter opens that note at that line" {
	printf '# A\n\nalpha\nbeta\n' >"$DIR/A.md"
	answer 0 "1 " # Search every note
	answer 0 "2 " # A:4 beta
	"$NOTES"
	rows 2 | grep -qx "A:4   beta"
	opened
	grep -q "nvim +4 $DIR/A.md$" "$CALLS"
}
