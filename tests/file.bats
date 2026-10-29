#!/usr/bin/env bats
# desktop file: open a file with what suits it, or copy its path or its content. Fake tools record
# what they were asked; pgrep answers from $RUNNING.

setup() {
	FILE="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/file"
	export CALLS="$BATS_TEST_TMPDIR/calls" RUNNING=""
	bin="$BATS_TEST_TMPDIR/bin" && mkdir -p "$bin"
	for tool in kitty xdg-open brave firefox chromium; do
		# shellcheck disable=SC2016 # expands when the fake runs
		printf '#!/bin/sh\necho "%s $*" >>"$CALLS"\n' "$tool" >"$bin/$tool"
	done
	# xclip and wl-copy: also what they were given on stdin
	for tool in xclip wl-copy; do
		# shellcheck disable=SC2016
		printf '#!/bin/sh\necho "%s $* <$(cat)>" >>"$CALLS"\n' "$tool" >"$bin/$tool"
	done
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
	[ "$(cat "$CALLS")" = "xclip -selection clipboard -t UTF8_STRING -i <$d/notes.md>" ]
}

@test "content copies text as text, an image as an image, anything else as the file" {
	"$FILE" content "$d/notes.md"
	"$FILE" content "$d/dot.png"
	"$FILE" content "$d/blob.bin"
	[ "$(sed -n 1p "$CALLS")" = "xclip -selection clipboard -t UTF8_STRING -i <hello>" ]
	grep -aq "^xclip -selection clipboard -t image/png -i <" "$CALLS" # the picture's bytes follow
	[ "$(tail -1 "$CALLS")" = "xclip -selection clipboard -t text/uri-list -i <file://$d/blob.bin"$'\r'">" ]
}

@test "file copies the file itself, to paste as an attachment: only text/uri-list, encoded, CRLF" {
	printf 'x' >"$d/my report é.pdf"
	"$FILE" file "$d/my report é.pdf"
	[ "$(cat "$CALLS")" = "xclip -selection clipboard -t text/uri-list -i <file://$d/my%20report%20%C3%A9.pdf"$'\r'">" ]
}

@test "on Wayland the file goes through copy-exact (wl-copy would add text/plain)" {
	# shellcheck disable=SC2016
	printf '#!/bin/sh\necho "copy-exact $* <$(cat)>" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/copy-exact"
	chmod +x "$BATS_TEST_TMPDIR/bin/copy-exact"
	DESKTOP_COPY_EXACT="$BATS_TEST_TMPDIR/bin/copy-exact" WAYLAND_DISPLAY=wayland-1 "$FILE" file "$d/notes.md"
	grep -q "^copy-exact text/uri-list <file://$d/notes.md" "$CALLS"
}

@test "Wayland copies with wl-copy" {
	WAYLAND_DISPLAY=wayland-1 "$FILE" path "$d/notes.md"
	[ "$(cat "$CALLS")" = "wl-copy --type text/plain;charset=utf-8 <$d/notes.md>" ]
}

@test "a missing file or bad usage fails" {
	run "$FILE" open "$d/nope.txt"
	[ "$status" -eq 1 ]
	run "$FILE" frobnicate "$d/notes.md"
	[ "$status" -eq 2 ]
}

home_files() { # a home with your files, settings and app caches in dot-folders, and dependencies
	export HOME="$BATS_TEST_TMPDIR/home" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/home/.config" XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
	mkdir -p "$HOME/notes" "$HOME/src/node_modules/x" "$HOME/.cache" "$HOME/.config/teams/Cache" "$HOME/.config/nvim" "$HOME/go/pkg"
	touch -d '-3 hours' "$HOME/notes/todo.md" "$HOME/src/main.go" "$HOME/src/node_modules/x/todo.js" "$HOME/.cache/todo.md" \
		"$HOME/.config/teams/Cache/todo.log" "$HOME/.config/nvim/init.lua" "$HOME/.zshrc" "$HOME/go/pkg/todo.go"
}

@test "find searches your own files: not dot-folders (settings, app caches) or dependencies" {
	home_files
	run "$FILE" find todo
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "$HOME/notes/todo.md" ]
	[[ $output != *"/.cache/"* && $output != *"/.config/"* && $output != *node_modules* ]]
	run "$FILE" find zshrc
	[ -z "$output" ] # a dotfile: type its path (~/.zs)
}

@test "fd's ignore file leaves out more (tool data such as ~/go)" {
	home_files
	run "$FILE" find todo
	[[ $output == *"$HOME/go/pkg/todo.go"* ]]
	mkdir -p "$XDG_CONFIG_HOME/fd" && echo /go/ >"$XDG_CONFIG_HOME/fd/ignore"
	rm -rf "$XDG_RUNTIME_DIR/desktop" # not the list from a moment ago
	run "$FILE" find todo
	[ "$output" = "$HOME/notes/todo.md" ]
}

@test "a path searches that folder, hidden files too: ~/.config/nv, /etc/, ~/.zs" {
	home_files
	run "$FILE" find "~/.config/nv"
	[ "$output" = "$HOME/.config/nvim/" ] # a folder ends in /
	run "$FILE" find "~/.config/init"
	[ "$output" = "$HOME/.config/nvim/init.lua" ] # found under it too
	[[ $output != *teams* ]]
	run "$FILE" find "~/.zs"
	[ "$output" = "$HOME/.zshrc" ]
	mkdir -p "$BATS_TEST_TMPDIR/etc/pacman.d" && touch "$BATS_TEST_TMPDIR/etc/pacman.conf" "$BATS_TEST_TMPDIR/etc/hosts"
	run "$FILE" find "$BATS_TEST_TMPDIR/etc/pac"
	[[ $output == *"$BATS_TEST_TMPDIR/etc/pacman.conf"* && $output == *"$BATS_TEST_TMPDIR/etc/pacman.d/"* ]]
	[[ $output != *hosts* ]]
	run "$FILE" find "$BATS_TEST_TMPDIR/etc/"
	[[ $output == *"$BATS_TEST_TMPDIR/etc/hosts"* ]] # just the folder: what's in it
	run "$FILE" find "/no/such/place/x"
	[ "$status" -eq 0 ] && [ -z "$output" ]
}

@test "find with no query lists your files changed lately, newest first" {
	home_files
	mkdir -p "$HOME/a"
	touch -d '-2 hours' "$HOME/a/older.txt"
	touch "$HOME/a/newer.txt"
	run "$FILE" find
	[ "${lines[0]}" = "$HOME/a/newer.txt" ]
	[[ $output == *"$HOME/a/older.txt"* ]]
	[[ $output != *"/.cache/"* && $output != *"/.config/"* ]]
}

@test "content of a picture keeps its own type (an SVG isn't labelled PNG)" {
	printf '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>\n' >"$d/pic.svg"
	"$FILE" content "$d/pic.svg"
	grep -aq "^xclip -selection clipboard -t image/svg+xml -i <" "$CALLS"
}

@test "the launcher's ~/ start: ~/ alone is the recent list, ~/word your files, ~/.x your dotfiles" {
	home_files
	touch "$HOME/notes/fresh.md"
	run "$FILE" find "~/"
	[ "${lines[0]}" = "$HOME/notes/fresh.md" ]
	run "$FILE" find "~/todo"
	[ "${lines[0]}" = "$HOME/notes/todo.md" ]
	[[ $output != *"/.cache/"* && $output != *"/.config/"* ]]
	run "$FILE" find "~/.co"
	[ "${lines[0]}" = "$HOME/.config/" ] # what's in home starting with a dot: not inside it yet
	[[ $output != *"/.config/nvim"* ]]
}

@test "a search reuses its folder's file list for a while (typing doesn't rescan)" {
	home_files
	export XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run" && mkdir -p "$XDG_RUNTIME_DIR"
	run "$FILE" find todo
	touch "$HOME/notes/todo-new.md"
	run "$FILE" find todo
	[[ $output != *todo-new.md* ]] # the list from a moment ago
	find "$XDG_RUNTIME_DIR/desktop" -type f -exec touch -d '-3 minutes' {} +
	run "$FILE" find todo
	[[ $output == *todo-new.md* ]] # older than that: listed again
}

@test "names match as Nautilus does: the words inside the name, not scattered letters or folder names" {
	home_files
	mkdir -p "$HOME/work/reports" && touch "$HOME/work/reports/q3 sales.pdf" "$HOME/work/sales-old.txt" "$HOME/work/summary.md"
	run "$FILE" find tdo
	[ -z "$output" ] # fuzzy would have found todo.md
	run "$FILE" find "sales q3"
	[ "$output" = "$HOME/work/reports/q3 sales.pdf" ] # every word, any order
	run "$FILE" find reports
	[ "$output" = "$HOME/work/reports/" ] # the folder, not the files in it
	run "$FILE" find sal
	[ "${lines[0]}" = "$HOME/work/sales-old.txt" ] # a name that starts with it comes first
}
