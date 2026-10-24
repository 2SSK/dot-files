#!/usr/bin/env bats
# The YouTube workflow: yt-new (project folders), voiceover (Piper) and captions (whisper), the last
# two with fakes that record what they're asked.

setup() {
	BIN="$BATS_TEST_DIRNAME/../.local/bin"
	export CALLS="$BATS_TEST_TMPDIR/calls" YT_DIR="$BATS_TEST_TMPDIR/yt" XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
	fake="$BATS_TEST_TMPDIR/bin" && mkdir -p "$fake"
	# shellcheck disable=SC2016 # expand when the fakes run
	{
		printf '#!/bin/sh\necho "piper $*" >>"$CALLS"\nwhile [ $# -gt 0 ]; do [ "$1" = -f ] && echo wav >"$2"; shift; done\n' >"$fake/piper"
		printf '#!/bin/sh\necho "ffmpeg $*" >>"$CALLS"\nfor last; do :; done\necho wav >"$last"\n' >"$fake/ffmpeg"
		printf '#!/bin/sh\necho "whisper $*" >>"$CALLS"\nfor last; do :; done\n[ -n "$NO_OUTPUT" ] || echo srt >"${last%%.*}.srt"\n' >"$fake/whisper-ctranslate2"
		printf '#!/bin/sh\necho "download $*" >>"$CALLS"\nfor last; do :; done\nwhile [ $# -gt 0 ]; do [ "$1" = --data-dir ] && dir=$2; shift; done\ntouch "$dir/$last.onnx"\n' >"$fake/python"
	}
	chmod +x "$fake"/*
	export PATH="$fake:$PATH" PIPER_PYTHON="$fake/python"
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

@test "voiceover: the voice downloaded once, spoken, levelled into the project's audio folder" {
	dir="$("$BIN/yt-new" demo)" && echo "Hello." >"$dir/script.txt"
	run "$BIN/voiceover" "$dir/script.txt"
	[ "$status" -eq 0 ]
	[ "$output" = "$dir/audio/voiceover.wav" ] && [ -s "$output" ]
	grep -q "^download .*en_US-ryan-high" "$CALLS"
	grep -q "loudnorm=I=-16" "$CALLS"
	rm "$CALLS"
	"$BIN/voiceover" --hindi --speed 1.25 "$dir/script.txt" "$BATS_TEST_TMPDIR/hi.wav"
	grep -q "^download .*hi_IN-rohan-medium" "$CALLS"
	grep -q "piper .*--length-scale 0.800" "$CALLS"
	rm "$CALLS"
	"$BIN/voiceover" --hindi "$dir/script.txt" "$BATS_TEST_TMPDIR/hi.wav"
	! grep -q "^download" "$CALLS" # once only
}

@test "captions: subtitles beside the file, on the CPU; Hindi when asked; a failure says so" {
	echo video >"$BATS_TEST_TMPDIR/clip.mp4"
	run "$BIN/captions" "$BATS_TEST_TMPDIR/clip.mp4"
	[ "$status" -eq 0 ]
	[ "$output" = "$BATS_TEST_TMPDIR/clip.srt" ]
	grep -q "whisper .*--device cpu" "$CALLS"
	! grep -q -- "--language" "$CALLS" # detected
	"$BIN/captions" --hindi "$BATS_TEST_TMPDIR/clip.mp4"
	grep -q -- "--language hi" "$CALLS"
	NO_OUTPUT=1 run "$BIN/captions" "$BATS_TEST_TMPDIR/clip.mp4"
	[ "$status" -ne 0 ]
}
