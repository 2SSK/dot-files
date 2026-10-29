#!/usr/bin/env bats
# desktop vscodium: VSCodium's settings.json, the repo's base plus the rendered theme colours.

setup() {
	VSC="$BATS_TEST_DIRNAME/../.local/lib/desktop/bin/vscodium"
	export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
	theme="$XDG_STATE_HOME/desktop/theme" out="$XDG_CONFIG_HOME/VSCodium/User/settings.json"
	mkdir -p "$XDG_CONFIG_HOME/VSCodium" "$theme/vscodium"
	printf '// the base\n{\n\t// look\n\t"editor.fontSize": 14,\n\t"vim.leader": "<space>"\n}\n' >"$XDG_CONFIG_HOME/VSCodium/settings.jsonc"
	printf '{\n  "$comment": "rendered",\n  "workbench.colorCustomizations": { "editor.background": "#101010" },\n  "editor.tokenColorCustomizations": { "textMateRules": [] }\n}\n' >"$theme/vscodium/colors.json"
	printf 'family=gruvbox\nmode=dark\n' >"$theme/current"
}

parse() { # JSONC: the file without its comments and trailing commas
	python3 -c 'import re,json,sys; t=open(sys.argv[1]).read(); t=re.sub(r"^\s*//.*$","",t,flags=re.M); t=re.sub(r",(\s*[}\]])",r"\1",t); print(json.dumps(json.loads(t)))' "$1"
}

@test "the base's settings and comments, with the theme's colours on VSCodium's own dark theme" {
	run "$VSC"
	[ "$status" -eq 0 ]
	grep -qx $'\t// look' "$out"
	json="$(parse "$out")"
	[ "$(jq -r '."editor.fontSize"' <<<"$json")" = 14 ]
	[ "$(jq -r '."workbench.colorTheme"' <<<"$json")" = "Default Dark Modern" ]
	[ "$(jq -r '."workbench.colorCustomizations"."editor.background"' <<<"$json")" = "#101010" ]
	[ "$(jq -r 'has("$comment")' <<<"$json")" = false ]
}

@test "a light theme: VSCodium's light one under the colours" {
	printf 'family=gruvbox\nmode=light\n' >"$theme/current"
	"$VSC"
	[ "$(parse "$out" | jq -r '."workbench.colorTheme"')" = "Default Light Modern" ]
}

@test "the old link to the repo's file is replaced by the written file; unchanged, it isn't rewritten" {
	mkdir -p "${out%/*}" && ln -s "$BATS_TEST_TMPDIR/nowhere.json" "$out"
	"$VSC"
	[ -f "$out" ] && [ ! -L "$out" ]
	touch -d '2000-01-01' "$out"
	"$VSC"
	[ "$(stat -c %Y "$out")" = "$(date -d '2000-01-01' +%s)" ]
}

@test "no base (VSCodium not set up here): nothing written" {
	rm "$XDG_CONFIG_HOME/VSCodium/settings.jsonc"
	run "$VSC"
	[ "$status" -eq 0 ]
	[ ! -e "$out" ]
}
