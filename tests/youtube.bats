#!/usr/bin/env bats
# yt-new: the YouTube project folders.

setup() {
	BIN="$BATS_TEST_DIRNAME/../.local/bin"
	export YT_DIR="$BATS_TEST_TMPDIR/yt"
}

@test "yt-new: a dated, slugged project with its folders and a script to write in" {
	run "$BIN/yt-new" "Kubernetes in 60 Seconds!"
	[ "$status" -eq 0 ]
	[[ $output == "$YT_DIR/"*"-kubernetes-in-60-seconds" ]]
	for d in raw audio edit export thumbs; do [ -d "$output/$d" ]; done
	head -1 "$output/script.txt" | grep -qx "Kubernetes in 60 Seconds!"
	run "$BIN/yt-new" "Kubernetes in 60 Seconds!"
	[ "$status" -ne 0 ] # never over an existing one
}
