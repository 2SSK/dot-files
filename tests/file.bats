#!/usr/bin/env bats
# desktop-file: open a file with what suits it, or copy its path or its content. Fake tools record
# what they were asked; pgrep answers from $RUNNING.

setup() {
	FILE="$BATS_TEST_DIRNAME/../.local/bin/desktop-file"
	export CALLS="$BATS_TEST_TMPDIR/calls" RUNNING=""
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	for tool in kitty xdg-open brave firefox chromium wl-copy; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$bin/$tool"
	done
	# xclip: also what it was given on stdin
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "xclip $* <$(cat)>" >>"$CALLS"\n' >"$bin/xclip"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\nfor p in $RUNNING; do [ "$p" = "$2" ] && exit 0; done\nexit 1\n' >"$bin/pgrep"
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "${DEFAULT_BROWSER:-}"\n' >"$bin/xdg-settings"
	chmod +x "$bin"/*
	export PATH="$bin:$PATH" EDITOR=nvim TERMINAL=kitty
	unset WAYLAND_DISPLAY
	d="$BATS_TEST_TMPDIR/files" && mkdir -p "$d"
	printf 'hello\n' >"$d/notes.md"
	printf '#!/bin/sh\necho hi\n' >"$d/run.sh"
	printf '<html><body>hi</body></html>\n' >"$d/page.html"
	printf '%%PDF-1.4\n%%EOF\n' >"$d/doc.pdf"
	magick -size 4x4 xc:red "$d/dot.png" 2>/dev/null || convert -size 4x4 xc:red "$d/dot.png"
	head -c 64 /dev/urandom >"$d/blob.bin"
}

@test "text and code open in the editor, in a terminal" {
	"$FILE" open "$d/notes.md"
	"$FILE" open "$d/run.sh"
	[ "$(sed -n 1p "$CALLS")" = "kitty -e nvim $d/notes.md" ]
	[ "$(sed -n 2p "$CALLS")" = "kitty -e nvim $d/run.sh" ]
}

@test "web pages and PDFs open in a new tab of the browser that's running" {
	RUNNING="firefox" "$FILE" open "$d/page.html"
	RUNNING="brave" "$FILE" open "$d/doc.pdf"
	[ "$(sed -n 1p "$CALLS")" = "firefox --new-tab file://$d/page.html" ]
	[ "$(sed -n 2p "$CALLS")" = "brave --new-tab file://$d/doc.pdf" ]
}

@test "with no browser running, the default one opens it" {
	DEFAULT_BROWSER=chromium.desktop "$FILE" open "$d/page.html"
	[ "$(cat "$CALLS")" = "chromium --new-tab file://$d/page.html" ]
}

@test "anything else goes to its default application" {
	"$FILE" open "$d/dot.png"
	[ "$(cat "$CALLS")" = "xdg-open $d/dot.png" ]
}

@test "path copies the full path as text" {
	cd "$d" && "$FILE" path notes.md
	[ "$(cat "$CALLS")" = "xclip -selection clipboard -t UTF8_STRING <$d/notes.md>" ]
}

@test "content copies text as text, an image as an image, anything else as the file" {
	"$FILE" content "$d/notes.md"
	"$FILE" content "$d/dot.png"
	"$FILE" content "$d/blob.bin"
	[ "$(sed -n 1p "$CALLS")" = "xclip -selection clipboard -t UTF8_STRING <hello>" ]
	grep -aq "^xclip -selection clipboard -t image/png <" "$CALLS" # the picture's bytes follow
	[ "$(tail -1 "$CALLS")" = "xclip -selection clipboard -t text/uri-list <file://$d/blob.bin>" ]
}

@test "Wayland copies with wl-copy" {
	WAYLAND_DISPLAY=wayland-1 "$FILE" path "$d/notes.md"
	[ "$(cat "$CALLS")" = "wl-copy --type text/plain;charset=utf-8 $d/notes.md" ]
}

@test "a missing file or bad usage fails" {
	run "$FILE" open "$d/nope.txt"
	[ "$status" -eq 1 ]
	run "$FILE" frobnicate "$d/notes.md"
	[ "$status" -eq 2 ]
}

@test "find lists matching files under home, best first, without .git or caches" {
	export HOME="$BATS_TEST_TMPDIR/home" XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
	mkdir -p "$HOME/notes" "$HOME/src/.git" "$HOME/.cache" "$HOME/src/node_modules/x" "$XDG_RUNTIME_DIR"
	touch "$HOME/notes/todo.md" "$HOME/src/main.go" "$HOME/src/.git/todo" "$HOME/.cache/todo.md" "$HOME/src/node_modules/x/todo.js" "$HOME/.zshrc"
	run "$FILE" find todo
	[ "$status" -eq 0 ]
	[ "$output" = "$HOME/notes/todo.md" ]
	run "$FILE" find zsh
	[ "$output" = "$HOME/.zshrc" ]
}

@test "find with no query lists the most recently changed first" {
	export HOME="$BATS_TEST_TMPDIR/home" XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
	mkdir -p "$HOME/a" "$XDG_RUNTIME_DIR"
	touch -d '-2 hours' "$HOME/a/older.txt"
	touch "$HOME/a/newer.txt"
	run "$FILE" find
	[ "${lines[0]}" = "$HOME/a/newer.txt" ]
	[ "${lines[1]}" = "$HOME/a/older.txt" ]
}
