#!/usr/bin/env bash
# Exit 0 when two trees of QML differ only in comments: each file with its // comments and blank
# lines taken out must be the same. (A // inside a string, as in file://, isn't a comment: only
# one with a space after it, at the start of a line or after a space, is.)
#   code-unchanged.sh <dir a> <dir b>
set -euo pipefail
strip() { sed -E -e '/^[[:space:]]*\/\/( |$)/d' -e 's/[[:space:]]+\/\/ .*$//' -e '/^[[:space:]]*$/d' "$1"; }
status=0
while IFS= read -r f; do
	if [[ ! -f $2/$f ]]; then echo "missing: $f"; status=1; continue; fi
	diff -q <(strip "$1/$f") <(strip "$2/$f") >/dev/null || { echo "code changed: $f"; diff <(strip "$1/$f") <(strip "$2/$f") | head -6; status=1; }
done < <(cd "$1" && find . -name '*.qml' | sort)
exit $status
