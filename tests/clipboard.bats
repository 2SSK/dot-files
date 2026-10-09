#!/usr/bin/env bats
# desktop-clipboard: what was just copied, as one JSON line for the shell's history (text in
# memory, an image saved to the runtime folder, files by path), and copying an entry back as what it
# was. Fake xclip and wl-paste answer from files: $TYPES lists the offered types, $DATA_<type> holds
# each type's bytes.

setup() {
	CLIP="$BATS_TEST_DIRNAME/../.local/bin/desktop-clipboard"
	export CALLS="$BATS_TEST_TMPDIR/calls" XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run" OFFER="$BATS_TEST_TMPDIR/offer"
	mkdir -p "$BATS_TEST_TMPDIR/bin" "$XDG_RUNTIME_DIR" "$OFFER"
	# xclip: -o -t TARGETS lists the types; -o -t <type> prints it; -i records what's copied
	cat >"$BATS_TEST_TMPDIR/bin/xclip" <<'FAKE'
#!/bin/sh
out=0 type=
while [ $# -gt 0 ]; do case $1 in -o) out=1 ;; -t) type=$2; shift ;; esac; shift; done
if [ $out = 1 ]; then
	if [ "$type" = TARGETS ]; then cat "$OFFER/types"; else cat "$OFFER/$(echo "$type" | tr / _)"; fi
else
	echo "xclip copy $type <$(base64 -w0)>" >>"$CALLS"
fi
FAKE
	chmod +x "$BATS_TEST_TMPDIR/bin/xclip"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH" DISPLAY=:0
	unset WAYLAND_DISPLAY
}

offer() { # <type> <data...>: what the clipboard holds
	echo "$1" >>"$OFFER/types"
	printf '%s' "$2" >"$OFFER/$(echo "$1" | tr / _)"
}

json() { python3 -c "import json,sys; d=json.loads(sys.argv[1]); print($1)" "$output"; }

@test "text is reported as text, not saved anywhere" {
	offer UTF8_STRING "hello world"
	run "$CLIP" store
	[ "$status" -eq 0 ]
	[ "$(json 'd["kind"], d["text"]')" = "text hello world" ]
	[ -z "$(ls "$XDG_RUNTIME_DIR/desktop/clipboard" 2>/dev/null)" ]
}

@test "an image is saved in the runtime folder, once per picture" {
	offer image/png "PNGDATA"
	offer TARGETS ""
	run "$CLIP" store
	[ "$(json 'd["kind"]')" = image ]
	path="$(json 'd["path"]')"
	[ "$(cat "$path")" = PNGDATA ]
	[[ $path == "$XDG_RUNTIME_DIR/desktop/clipboard/"*.png ]]
	run "$CLIP" store
	[ "$(ls "$XDG_RUNTIME_DIR/desktop/clipboard" | wc -l)" -eq 1 ]
}

@test "files are reported by path" {
	offer text/uri-list $'file:///home/me/my%20report.pdf\r\nfile:///home/me/a.png\r\n'
	offer UTF8_STRING "file:///home/me/my%20report.pdf"
	run "$CLIP" store
	[ "$(json 'd["kind"], *d["paths"]')" = "files /home/me/my report.pdf /home/me/a.png" ]
}

@test "a password manager's copy is left out" {
	offer x-kde-passwordManagerHint secret
	offer UTF8_STRING "hunter2"
	run "$CLIP" store
	[ -z "$output" ]
}

@test "copy puts an image back as an image, and files as files" {
	printf 'PNGDATA' >"$BATS_TEST_TMPDIR/shot.png"
	"$CLIP" copy image "$BATS_TEST_TMPDIR/shot.png"
	grep -qx "xclip copy image/png <$(printf PNGDATA | base64 -w0)>" "$CALLS"
	"$CLIP" copy files "/home/me/my report.pdf"
	grep -qx "xclip copy text/uri-list <$(printf 'file:///home/me/my%%20report.pdf\r\n' | base64 -w0)>" "$CALLS"
}
