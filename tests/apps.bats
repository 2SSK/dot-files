#!/usr/bin/env bats
# CLI app configs load in the real tools (skipped when a tool isn't installed).

setup() {
	REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	export HOME="$BATS_TEST_TMPDIR/home"
	mkdir -p "$HOME"
}

@test "pgcli accepts the config and its ANSI styles" {
	python3 -c 'import pgcli' 2>/dev/null || skip "pgcli not installed"
	run python3 -c "
from pgcli.main import PGCli
from pgcli.pgstyle import style_factory, style_factory_output
p = PGCli(pgclirc_file='$REPO/.config/pgcli/config')
style_factory(p.syntax_style, p.cli_style)
style_factory_output(p.syntax_style, p.cli_style)
assert p.vi_mode and p.multi_line"
	[ "$status" -eq 0 ]
}

@test "fastfetch accepts the config" {
	command -v fastfetch >/dev/null || skip "fastfetch not installed"
	run fastfetch -c "$REPO/.config/fastfetch/config.jsonc" --pipe
	[ "$status" -eq 0 ]
	[[ $output == *"----------------------------"* ]]
}

@test "app configs use ANSI colour names, not hard-coded hex" {
	run grep -lE "#[0-9a-fA-F]{6}" "$REPO"/.config/{lazygit,lazydocker,yazi,pgcli,fastfetch,tmux,btop}/*
	[ "$status" -eq 1 ]
}
