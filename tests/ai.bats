#!/usr/bin/env bats
# Claude Code and opencode configs: no secrets in the repo, and the secrets wrappers.

REPO="$BATS_TEST_DIRNAME/.."

@test "no token-shaped strings anywhere in the repo" {
	# GitHub, Grafana, OpenAI/Anthropic, AWS and Slack tokens, private keys; in what could be
	# committed (tracked, or new and not ignored), not local secrets like opencode/.env
	run git -C "$REPO" grep -InE --untracked \
		'(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|glsa_[A-Za-z0-9_]{20,}|sk-(ant-)?[A-Za-z0-9_-]{30,}|AKIA[0-9A-Z]{16}|xox[abpr]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
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

@test "only claude and opencode see ~/.config/secrets.env" {
	export HOME="$BATS_TEST_TMPDIR/home" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/home/.config"
	mkdir -p "$XDG_CONFIG_HOME" "$BATS_TEST_TMPDIR/bin"
	echo 'SUPERSET_API_KEY=s3cret' >"$XDG_CONFIG_HOME/secrets.env"
	for tool in claude opencode; do
		printf '#!/bin/sh\necho "%s:$SUPERSET_API_KEY"\n' "$tool" >"$BATS_TEST_TMPDIR/bin/$tool"
	done
	chmod +x "$BATS_TEST_TMPDIR"/bin/*
	unset SUPERSET_API_KEY # run from inside claude, the test would inherit the real one
	run bash -c "PATH='$BATS_TEST_TMPDIR/bin':\$PATH; source '$REPO/.config/shell/functions.sh'; claude; opencode; echo \"shell:\${SUPERSET_API_KEY:-unset}\""
	[ "$status" -eq 0 ]
	[ "$output" = $'claude:s3cret\nopencode:s3cret\nshell:unset' ]
}

@test "adb-mcp is in both tools, from a pinned, checksummed release" {
	jq -e '.adb == {"type": "stdio", "command": "adb-mcp"}' "$REPO/.config/mcp/claude.json"
	jq -e '.mcp.adb == {"type": "local", "command": ["adb-mcp"], "enabled": true}' "$REPO/.config/opencode/opencode.json"
	grep -qE '^@adb-mcp +@adb-mcp$' "$REPO/packages/dev.txt"
	grep -qE '^android-tools +android-tools$' "$REPO/packages/dev.txt"
	grep -qE '^version=[0-9]+\.[0-9]+\.[0-9]+$' "$REPO/packages/extra/adb-mcp.sh"
	grep -qE '[0-9a-f]{64} adb-mcp$' "$REPO/packages/extra/adb-mcp.sh"
}

@test "temporal-mcp: in both tools from a pinned, checksummed release; the real config stays local" {
	jq -e '.temporal == {"type": "stdio", "command": "temporal-mcp", "args": ["--stdio", "--config", "${HOME}/.config/temporal-mcp/config.yaml"]}' "$REPO/.config/mcp/claude.json"
	jq -e '.mcp.temporal == {"type": "local", "command": ["temporal-mcp", "--stdio", "--config", "{env:HOME}/.config/temporal-mcp/config.yaml"], "enabled": true}' "$REPO/.config/opencode/opencode.json"
	grep -qE '^@temporal-mcp +@temporal-mcp$' "$REPO/packages/dev.txt"
	# reading and investigating only: opencode never gets the one tool that writes (start a workflow)
	jq -e '.tools.temporal_start_workflow == false' "$REPO/.config/opencode/opencode.json"
	grep -qE '^version=[0-9]+\.[0-9]+\.[0-9]+$' "$REPO/packages/extra/temporal-mcp.sh"
	grep -qE '[0-9a-f]{64} temporal-mcp$' "$REPO/packages/extra/temporal-mcp.sh"
	# the repo has an example only: addresses are placeholders, and the real file is never tracked
	example="$REPO/.config/temporal-mcp/config.yaml.example"
	python3 -c 'import sys, yaml; t = yaml.safe_load(open(sys.argv[1]))["targets"]; assert all(x["address"].split(":")[0] in ("localhost", "temporal.staging.example") for x in t), t' "$example"
	run git -C "$REPO" check-ignore -q .config/temporal-mcp/config.yaml
	[ "$status" -eq 0 ]
}
