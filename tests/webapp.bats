#!/usr/bin/env bats
# webapp, with a fake curl that writes an icon (or fails, for a site without one).

setup() {
	WEBAPP="$BATS_TEST_DIRNAME/../.local/bin/webapp"
	export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$BATS_TEST_TMPDIR/bin"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\necho "curl $*" >>"$CALLS"\n[ -z "$NO_ICON" ] || exit 22\nwhile [ $# -gt 0 ]; do [ "$1" = -o ] && echo png >"$2"; shift; done\n' >"$BATS_TEST_TMPDIR/bin/curl"
	chmod +x "$BATS_TEST_TMPDIR/bin/curl"
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
	apps="$XDG_DATA_HOME/applications"
}

@test "add: a launcher entry opening the site in Brave's app mode, with its icon" {
	run "$WEBAPP" add ChatGPT https://chatgpt.com
	[ "$status" -eq 0 ]
	[ "$output" = "$apps/webapp-chatgpt.desktop" ]
	grep -qx "Name=ChatGPT" "$output"
	grep -qx "Exec=brave --app=https://chatgpt.com" "$output"
	grep -qx "StartupWMClass=brave-chatgpt.com__-Default" "$output"
	grep -qx "Icon=$XDG_DATA_HOME/icons/webapps/chatgpt.png" "$output"
	grep -q "curl .*domain=chatgpt.com&sz=256" "$CALLS"
}

@test "add: no icon to be had, the browser icon instead; a bad URL is refused" {
	NO_ICON=1 run "$WEBAPP" add "Google Docs" https://docs.google.com/document
	[ "$status" -eq 0 ]
	grep -qx "Icon=web-browser" "$apps/webapp-google-docs.desktop"
	grep -qx "StartupWMClass=brave-docs.google.com__-Default" "$apps/webapp-google-docs.desktop"
	[ ! -e "$XDG_DATA_HOME/icons/webapps/google-docs.png" ]
	run "$WEBAPP" add Nope chatgpt.com
	[ "$status" -eq 2 ]
}

@test "list and remove" {
	"$WEBAPP" add ChatGPT https://chatgpt.com
	run "$WEBAPP" list
	[[ $output == "ChatGPT"*"https://chatgpt.com" ]]
	run "$WEBAPP" remove chatgpt
	[ "$status" -eq 0 ]
	[ ! -e "$apps/webapp-chatgpt.desktop" ] && [ ! -e "$XDG_DATA_HOME/icons/webapps/chatgpt.png" ]
	run "$WEBAPP" remove chatgpt
	[ "$status" -eq 1 ]
}
