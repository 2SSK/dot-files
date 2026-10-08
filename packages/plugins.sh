#!/usr/bin/env bash
# Clone or update plugins to their pinned tag or commit. Offline and a no-op when already current.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"

# sync <dest> <repo> <ref> [build]: ref is a release tag or a full commit hash
sync() {
	local dest="$HOME/$1" repo=$2 ref=$3 build=${4:-}
	local pinned="$dest/.git/desktop-ref" stamp="$dest/.git/desktop-built" # ref checked out / built

	if [[ -e $dest && ! -d $dest/.git ]]; then
		die not_a_clone path="$dest" msg='move it away and re-run'
	fi
	if [[ $(cat "$pinned" 2>/dev/null) != "$ref" ]]; then
		if [[ ! -d $dest/.git ]]; then
			git init -q "$dest"
			git -C "$dest" remote add origin "$repo"
		fi
		git -C "$dest" fetch -q --depth 1 origin "$ref"
		git -C "$dest" -c advice.detachedHead=false checkout -q --force FETCH_HEAD
		git -C "$dest" submodule -q update --init --recursive --depth 1
		echo "$ref" >"$pinned"
		log_info synced path="$dest" ref="$ref"
	fi

	if [[ -n $build && $(cat "$stamp" 2>/dev/null) != "$ref" ]]; then
		(cd "$dest" && bash -c "$build") >/dev/null
		echo "$ref" >"$stamp"
		log_info built path="$dest" ref="$ref"
	fi
}

list="${1:-$here/plugins.txt}"
while read -r dest repo ref build; do
	[[ -z $dest || $dest == \#* ]] && continue
	sync "$dest" "$repo" "$ref" "$build" </dev/null
done <"$list"
