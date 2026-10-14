#!/usr/bin/env bats
# Spotify starts ad-free from every launcher: the user's spotify.desktop preloads spotify-adblock,
# and the package's own "Spotify (adblock)" entry is hidden so there's one Spotify.

setup() {
	APPS="$BATS_TEST_DIRNAME/../.local/share/applications"
}

@test "the Spotify entry preloads the ad blocker and keeps spotify: links" {
	grep -qx 'Exec=env LD_PRELOAD=/usr/lib/spotify-adblock.so spotify --uri=%u' "$APPS/spotify.desktop"
	grep -qx 'MimeType=x-scheme-handler/spotify;' "$APPS/spotify.desktop"
	desktop-file-validate "$APPS/spotify.desktop" 2>/dev/null || ! command -v desktop-file-validate >/dev/null
}

@test "the package's second entry is hidden" {
	grep -qx 'Hidden=true' "$APPS/spotify-adblock.desktop"
}

@test "both packages are in the lists, spicetify is removed" {
	grep -qE '^aur:spotify\s' "$BATS_TEST_DIRNAME/../packages/base.txt"
	grep -qE '^aur:spotify-adblock\s' "$BATS_TEST_DIRNAME/../packages/base.txt"
	grep -qx 'spicetify-cli' "$BATS_TEST_DIRNAME/../packages/remove.txt"
}
