#!/usr/bin/env bats
# Claude Code's status line: what it prints for the JSON Claude Code gives it.

setup() {
	BIN="$BATS_TEST_DIRNAME/../.local/bin/claude-statusline"
	repo="$BATS_TEST_TMPDIR/my-repo"
	git init -q "$repo"
	git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
}

# shellcheck disable=SC2001 # a regex, which ${var//} can't do
line() { sed 's/\x1b\[[0-9;]*m//g' <<<"$1"; } # without its colours

@test "model, limits, context and repo" {
	run "$BIN" <<<'{"model":{"display_name":"Opus"},"workspace":{"current_dir":"'"$repo"'"},"context_window":{"used_percentage":8},"rate_limits":{"five_hour":{"used_percentage":12.4},"seven_day":{"used_percentage":9}}}'
	[ "$status" -eq 0 ]
	[ "$(line "$output")" = "Opus | 5h 12% | 7d 9% | ctx 8% |  my-repo" ]
}

@test "changed and untracked files are counted" {
	echo a >"$repo/tracked" && git -C "$repo" add tracked
	echo b >"$repo/new"
	run "$BIN" <<<'{"model":{"display_name":"Opus"},"workspace":{"current_dir":"'"$repo"'"}}'
	[ "$(line "$output")" = "Opus |  my-repo !1 ?1" ]
}

@test "values Claude Code leaves out, and no repo, leave no gaps" {
	run "$BIN" <<<'{"model":{"display_name":"Opus"},"workspace":{"current_dir":"'"$BATS_TEST_TMPDIR"'"}}'
	[ "$(line "$output")" = "Opus" ]
}

@test "a high percentage turns red" {
	run "$BIN" <<<'{"model":{"display_name":"Opus"},"context_window":{"used_percentage":85}}'
	[[ $output == *$'\e[31m85%'* ]]
}
