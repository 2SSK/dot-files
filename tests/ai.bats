#!/usr/bin/env bats
# Claude Code and opencode configs: no secrets in the repo, mcp-sync, and the secrets wrappers.

REPO="$BATS_TEST_DIRNAME/.."

@test "no token-shaped strings anywhere in the repo" {
	# GitHub, Grafana, OpenAI/Anthropic, AWS and Slack tokens, private keys
	run grep -rInE --exclude-dir=.git --exclude-dir=__pycache__ \
		'(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|glsa_[A-Za-z0-9_]{20,}|sk-(ant-)?[A-Za-z0-9_-]{30,}|AKIA[0-9A-Z]{16}|xox[abpr]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' "$REPO"
	[ "$status" -eq 1 ] || { echo "$output" && false; }
}

@test "MCP credentials and hosts are placeholders only" {
	# Claude: every env, header and url value is a ${VAR} placeholder (public URLs aside)
	run jq -r '.[] | (.env // {}), (.headers // {}) | .[] | select(test("^\\$\\{[A-Z0-9_]+\\}$") | not)' "$REPO/.config/mcp/claude.json"
	[ -z "$output" ] || { echo "literal in claude.json: $output" && false; }
	# opencode: environment and header values are {env:VAR}
	run jq -r '.mcp[] | (.environment // {}), (.headers // {}) | .[] | select(test("^\\{env:[A-Z0-9_]+\\}$") | not)' "$REPO/.config/opencode/opencode.json"
	[ -z "$output" ] || { echo "literal in opencode.json: $output" && false; }
	# every variable they use is listed in the example secrets file
	for var in $(grep -ohE '(\$\{|\{env:)[A-Z0-9_]+' "$REPO/.config/mcp/claude.json" "$REPO/.config/opencode/opencode.json" | sed -E 's/^(\$\{|\{env:)//' | sort -u); do
		[[ $var == HOME ]] || grep -q "^$var=" "$REPO/.config/secrets.env.example" || { echo "missing in example: $var" && false; }
	done
}

@test "mcp-sync registers every server with placeholders, replacing old entries" {
	export HOME="$BATS_TEST_TMPDIR/home" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/home/.config" CALLS="$BATS_TEST_TMPDIR/calls"
	mkdir -p "$XDG_CONFIG_HOME/mcp" "$BATS_TEST_TMPDIR/bin"
	cp "$REPO/.config/mcp/claude.json" "$XDG_CONFIG_HOME/mcp/claude.json"
	# shellcheck disable=SC2016 # expands when the fake runs
	printf '#!/bin/sh\nprintf "%%s\\n" "claude $*" >>"$CALLS"\n' >"$BATS_TEST_TMPDIR/bin/claude"
	chmod +x "$BATS_TEST_TMPDIR/bin/claude"
	PATH="$BATS_TEST_TMPDIR/bin:$PATH" run "$REPO/.local/bin/mcp-sync"
	[ "$status" -eq 0 ]
	[ "$(grep -c '^claude mcp add-json --scope user' "$CALLS")" -eq "$(jq length "$REPO/.config/mcp/claude.json")" ]
	grep -q '^claude mcp remove --scope user superset$' "$CALLS"
	grep -q 'add-json --scope user superset {"type":"http","url":"${SUPERSET_MCP_URL}","headers":{"X-API-Key":"${SUPERSET_API_KEY}"}}' "$CALLS"
}

@test "only claude and opencode see ~/.config/secrets.env" {
	export HOME="$BATS_TEST_TMPDIR/home" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/home/.config"
	mkdir -p "$XDG_CONFIG_HOME" "$BATS_TEST_TMPDIR/bin"
	echo 'SUPERSET_API_KEY=s3cret' >"$XDG_CONFIG_HOME/secrets.env"
	for tool in claude opencode; do
		printf '#!/bin/sh\necho "%s:$SUPERSET_API_KEY"\n' "$tool" >"$BATS_TEST_TMPDIR/bin/$tool"
	done
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	run bash -c "PATH='$BATS_TEST_TMPDIR/bin':\$PATH; source '$REPO/.config/shell/functions.sh'; claude; opencode; echo \"shell:\${SUPERSET_API_KEY:-unset}\""
	[ "$status" -eq 0 ]
	[ "$output" = $'claude:s3cret\nopencode:s3cret\nshell:unset' ]
}
