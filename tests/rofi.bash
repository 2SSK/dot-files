# shellcheck shell=bash
# A fake rofi for the menu tests (load rofi): each call takes the next line of $ROFI_ANSWERS,
# "<exit code><TAB><what it prints>" (no line left: Esc, exit 1), records its arguments in
# $CALLS ("rofi <args>") and the rows it was given in $BATS_TEST_TMPDIR/rofi-in.<n> (n from 1).

fake_rofi() { # <bin folder>
	export ROFI_ANSWERS="$BATS_TEST_TMPDIR/rofi-answers" ROFI_COUNT="$BATS_TEST_TMPDIR/rofi-count"
	: >"$ROFI_ANSWERS"
	cat >"$1/rofi" <<'EOF'
#!/usr/bin/env bash
n=$(($(cat "$ROFI_COUNT" 2>/dev/null || echo 0) + 1))
echo "$n" >"$ROFI_COUNT"
echo "rofi $*" >>"$CALLS"
cat >"$BATS_TEST_TMPDIR/rofi-in.$n"
line="$(sed -n "${n}p" "$ROFI_ANSWERS")"
[[ -n $line ]] || exit 1
printf '%s\n' "${line#*$'\t'}"
exit "${line%%$'\t'*}"
EOF
	chmod +x "$1/rofi"
}

answer() { # <exit code> [output]: the next rofi call's answer
	printf '%s\t%s\n' "$1" "${2:-}" >>"$ROFI_ANSWERS"
}

rows() { # <n>: the rows rofi call n was given
	cat "$BATS_TEST_TMPDIR/rofi-in.$1"
}
